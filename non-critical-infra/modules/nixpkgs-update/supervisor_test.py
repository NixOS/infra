#!/usr/bin/env python3

"""
In-process unit and integration tests for supervisor.py. Uses temporary
directories and memory for all state; cleans up after itself; has no
dependencies beyond what's in the nix-shell directive above and
supervisor.py itself. Run with confidence.
"""

import asyncio
import contextlib
import pathlib
import shutil
import socket
import sqlite3
import tempfile
import time
import unittest
from threading import Thread

import supervisor


def mkdtemp():
    return pathlib.Path(
        tempfile.mkdtemp(prefix="nix-community-infra-build02-supervisor-test-")
    )


def tick():
    time.sleep(0.01)


class UsesFetchers:
    def fetcher(self, name):
        return self.fetchers_path / name

    def write_fetcher(self, name, text):
        with self.fetcher(name).open("a") as f:
            f.write(text)
            f.flush()

    def finish_fetcher(self, name):
        self.fetcher(name).rename(self.fetcher(name.removesuffix(".part")))


class UsesDatabase:
    def connect(self):
        return contextlib.closing(sqlite3.connect(self.db_path, isolation_level=None))


class StorageTestCase(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:", isolation_level=None)
        self.enterContext(contextlib.closing(self.conn))
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.storage = supervisor.Storage(self.conn)
        self.storage.upgrade()

    def execute(self, *args):
        return self.conn.execute(*args)

    def assertDBContents(self, query, expected):
        self.assertEqual(set(self.execute(query).fetchall()), expected)

    def test_upsert_same_fetcher(self):
        self.storage.upsert_fetcher_run("f1", 100, False)
        self.storage.enqueue("f1", 100, [("alpha", "0 1")])
        self.storage.upsert_fetcher_run("f1", 100, True)
        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` from `queue`",
            {(1, "alpha", "0 1")},
        )

    def test_upsert_new_fetcher_generation(self):
        self.storage.upsert_fetcher_run("f1", 100, False)
        self.storage.enqueue("f1", 100, [("alpha", "0.1 1.0")])
        self.storage.upsert_fetcher_run("f1", 101, False)
        self.storage.enqueue("f1", 101, [("alpha", "0.1 1.1")])
        self.assertDBContents(
            "SELECT `fetcher_id`, `fetcher_run_started`, `attr_path`, `payload` from `queue`",
            {(1, 100, "alpha", "0.1 1.0"), (1, 101, "alpha", "0.1 1.1")},
        )

    def test_queue_insert_started(self):
        self.execute(
            """
            INSERT INTO `log` (`attr_path`, `started`)
            VALUES
                ('alpha', 103),
                ('charlie', 100)
            """
        )

        self.storage.upsert_fetcher_run("f1", 101, False)
        self.storage.upsert_fetcher_run("f2", 102, False)
        self.storage.enqueue("f1", 101, [("alpha", "0 1"), ("bravo", "0 1")])
        self.storage.enqueue("f2", 102, [("alpha", "1.2.3 1.2.4")])

        self.assertDBContents(
            "SELECT `attr_path`, `payload`, `last_started` FROM `queue`",
            {
                ("alpha", "0 1", 103),
                ("alpha", "1.2.3 1.2.4", 103),
                ("bravo", "0 1", None),
            },
        )

    def test_log_insert_started(self):
        self.storage.upsert_fetcher_run("f1", 100, False)
        self.storage.enqueue("f1", 100, [("alpha", "0 1"), ("bravo", "0 1")])

        self.execute("INSERT INTO `log` (`attr_path`, `started`) VALUES ('alpha', 101)")

        self.assertDBContents(
            "SELECT `attr_path`, `payload`, `last_started` FROM `queue`",
            {("alpha", "0 1", 101), ("bravo", "0 1", None)},
        )

    def test_log_update_started(self):
        self.execute("INSERT INTO `log` (`attr_path`, `started`) VALUES ('alpha', 100)")

        self.storage.upsert_fetcher_run("f1", 101, False)
        self.storage.upsert_fetcher_run("f2", 102, False)
        self.storage.enqueue("f1", 101, [("alpha", "0 1"), ("bravo", "0 1")])
        self.storage.enqueue("f2", 102, [("alpha", "1.2.3 1.2.4")])

        self.execute("UPDATE `log` SET `started` = 103 WHERE `attr_path` == 'alpha'")

        self.assertDBContents(
            "SELECT `attr_path`, `payload`, `last_started` FROM `queue`",
            {
                ("alpha", "0 1", 103),
                ("alpha", "1.2.3 1.2.4", 103),
                ("bravo", "0 1", None),
            },
        )

    def test_delete_fetcher_run_cleans_queue(self):
        self.storage.upsert_fetcher_run("f1", 100, False)
        self.storage.upsert_fetcher_run("f2", 101, False)
        self.storage.enqueue("f1", 100, [("alpha", "0 1")])
        self.storage.enqueue(
            "f2", 101, [("alpha", "1.2.3 1.2.4"), ("bravo", "0.1 0.1.1")]
        )
        self.storage.enqueue("f1", 100, [("charlie", "0 1")])

        self.storage.delete_fetcher_run("f1", 100)

        self.assertDBContents(
            "SELECT `fetcher_id`, `fetcher_run_started`, `attr_path`, `payload` FROM `queue`",
            {(2, 101, "alpha", "1.2.3 1.2.4"), (2, 101, "bravo", "0.1 0.1.1")},
        )

    def test_dequeue_and_finish(self):
        self.storage.upsert_fetcher_run("f1", 100, False)
        self.storage.upsert_fetcher_run("f2", 101, False)
        self.storage.enqueue("f1", 100, [("alpha", "0 1"), ("bravo", "0 1")])
        self.storage.enqueue(
            "f2", 101, [("alpha", "1.2.3 1.2.4"), ("charlie", "0.1 0.1.1")]
        )

        dequeued = {
            self.storage.dequeue(102)[0],
            self.storage.dequeue(103)[0],
            self.storage.dequeue(104)[0],
        }
        self.assertEqual(dequeued, {"alpha", "bravo", "charlie"})
        self.assertEqual(
            self.storage.dequeue(105), None
        )  # alpha is excluded because it's in flight
        self.storage.finish("alpha", 105, 0)
        self.assertEqual(self.storage.dequeue(105)[0], "alpha")
        self.assertEqual(self.storage.dequeue(106), None)  # queue is truly empty

        self.storage.delete_fetcher_run("f2", 101)
        self.storage.upsert_fetcher_run("f2", 106, False)
        self.storage.enqueue(
            "f2", 106, [("alpha", "1.2.3 1.2.5"), ("bravo", "0.25 0.27")]
        )
        self.storage.enqueue("f1", 100, [("delta", "0 1")])

        self.assertEqual(self.storage.dequeue(107), ("delta", "0 1"))
        self.assertEqual(self.storage.dequeue(108), None)  # bravo is excluded
        self.storage.finish("bravo", 108, 0)
        self.storage.finish("charlie", 108, 0)
        self.storage.finish("delta", 108, 0)
        self.assertEqual(self.storage.dequeue(108), ("bravo", "0.25 0.27"))
        self.storage.finish("alpha", 109, 0)
        self.assertEqual(self.storage.dequeue(109), ("alpha", "1.2.3 1.2.5"))
        self.assertEqual(self.storage.dequeue(110), None)

        self.storage.upsert_fetcher_run("f2", 106, True)
        self.storage.upsert_fetcher_run("f2", 110, False)
        self.storage.enqueue(
            "f2",
            110,
            [("alpha", "1.2.3 1.2.5"), ("bravo", "0.25 0.27"), ("charlie", "0.1 0.2")],
        )

        self.assertEqual(self.storage.dequeue(111), ("charlie", "0.1 0.2"))
        self.assertEqual(self.storage.dequeue(112), None)

    def test_exclusion_period(self):
        self.storage.upsert_fetcher_run("f1", 10000, False)
        self.storage.upsert_fetcher_run("f2", 10000, False)
        self.storage.enqueue("f1", 10000, [("alpha", "0 1")])
        self.storage.enqueue("f2", 10000, [("alpha", "1.0 1.1")])

        payloads = set()
        dequeued = self.storage.dequeue(10000)
        self.assertEqual(dequeued[0], "alpha")
        payloads.add(dequeued[1])
        self.assertEqual(self.storage.dequeue(10000), None)
        # Even though alpha hasn't finished, after enough time let the other
        # alpha task run anyway.
        dequeued = self.storage.dequeue(60000)
        self.assertEqual(dequeued[0], "alpha")
        payloads.add(dequeued[1])
        self.assertEqual(payloads, {"0 1", "1.0 1.1"})

    def test_continue_old_fetcher(self):
        self.execute(
            """
            INSERT INTO `log` (`attr_path`, `started`, `finished`, `exit_code`)
            VALUES
                ('alpha', 103, 105, 0),
                ('bravo', 101, 106, 0),
                ('charlie', 102, 107, 0)
            """
        )
        self.storage.upsert_fetcher_run("f1", 110, False)
        self.storage.enqueue(
            "f1",
            110,
            [
                ("alpha", "0.1 0.2"),
                ("bravo", "0.1 0.2"),
                ("charlie", "0.1 0.2"),
                ("delta", "0.1 0.2"),
            ],
        )
        self.assertEqual(self.storage.dequeue(111), ("delta", "0.1 0.2"))
        self.storage.finish("delta", 111, 0)
        self.assertEqual(self.storage.dequeue(112), ("bravo", "0.1 0.2"))
        self.storage.finish("bravo", 111, 0)
        self.storage.upsert_fetcher_run("f1", 113, False)
        self.storage.enqueue(
            "f1",
            113,
            [
                ("alpha", "0.1 0.3"),
                ("bravo", "0.1 0.3"),
                ("delta", "0.1 0.3"),
            ],
        )
        self.assertEqual(self.storage.dequeue(114), ("charlie", "0.1 0.2"))
        self.storage.finish("charlie", 114, 0)
        self.assertEqual(self.storage.dequeue(115), ("alpha", "0.1 0.3"))
        self.storage.finish("alpha", 115, 0)
        self.assertEqual(self.storage.dequeue(116), ("delta", "0.1 0.3"))
        self.storage.finish("delta", 116, 0)
        self.assertEqual(self.storage.dequeue(117), ("bravo", "0.1 0.3"))
        self.storage.finish("bravo", 117, 0)
        self.assertEqual(self.storage.dequeue(118), None)


class SupervisorTestCase(unittest.TestCase, UsesDatabase, UsesFetchers):
    def setUp(self):
        self.playground = mkdtemp()
        self.fetchers_path = self.playground / "~fetchers"
        self.db_path = self.playground / "state.db"
        self.socket_path = self.playground / "work.sock"

    def tearDown(self):
        shutil.rmtree(self.playground)

    def assertDBContents(self, query, expected):
        with self.connect() as conn:
            self.assertEqual(set(conn.execute(query).fetchall()), expected)

    def worker_request(self, msg):
        with socket.socket(socket.AF_UNIX) as sock:
            sock.settimeout(1)
            sock.connect(str(self.socket_path))
            sock.send(msg)
            sock.shutdown(socket.SHUT_WR)
            return sock.recv(4096)

    @contextlib.contextmanager
    def supervisor(self):
        with contextlib.closing(asyncio.new_event_loop()) as event_loop:

            def thread_target():
                asyncio.set_event_loop(event_loop)
                with contextlib.suppress(asyncio.CancelledError):
                    event_loop.run_until_complete(
                        supervisor.main(
                            self.db_path, self.fetchers_path, self.socket_path
                        )
                    )

            supervisor_thread = Thread(target=thread_target)
            supervisor_thread.start()

            def cancel_all():
                for task in asyncio.all_tasks():
                    task.cancel()

            try:
                tick()
                yield
                tick()
            finally:
                event_loop.call_soon_threadsafe(cancel_all)
                supervisor_thread.join()

    def test_enqueue_from_nothing(self):
        with self.supervisor():
            self.write_fetcher("f1.100.txt.part", "alpha 0 1\n")
            tick()
            self.write_fetcher("f1.100.txt.part", "bravo 0 1\n")

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(1, "alpha", "0 1"), (1, "bravo", "0 1")},
        )

    def test_enqueue_from_existing_files(self):
        self.fetchers_path.mkdir()
        self.write_fetcher("f1.100.txt", "alpha 0 1\n")
        with self.supervisor():
            pass

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(1, "alpha", "0 1")},
        )

    def test_delete_existing_files(self):
        self.fetchers_path.mkdir()
        self.write_fetcher("f1.100.txt", "alpha 0 1\n")
        with self.supervisor():
            self.fetcher("f1.100.txt").unlink()

        self.assertDBContents("SELECT * FROM `queue`", set())

    def test_append_existing_files(self):
        self.fetchers_path.mkdir()
        self.write_fetcher("f1.100.txt.part", "alpha 0 1\n")
        with self.supervisor():
            self.assertDBContents(
                "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
                {(1, "alpha", "0 1")},
            )
            self.write_fetcher("f1.100.txt.part", "bravo 0 1\n")

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(1, "alpha", "0 1"), (1, "bravo", "0 1")},
        )

    def test_replace_existing_files(self):
        self.fetchers_path.mkdir()
        self.write_fetcher("f1.100.txt.part", "alpha 0 1\n")
        self.write_fetcher("f2.101.txt.part", "bravo 0 1\n")
        with self.supervisor():
            self.assertDBContents(
                "SELECT `attr_path` FROM `queue`", {("alpha",), ("bravo",)}
            )
            self.finish_fetcher("f1.100.txt.part")
            self.write_fetcher("f1.102.txt.part", "charlie 0 1\n")
            tick()
            self.assertDBContents(
                "SELECT `attr_path` FROM `queue`",
                {("alpha",), ("bravo",), ("charlie",)},
            )

            self.fetcher("f1.100.txt").unlink()

        self.assertDBContents(
            "SELECT `attr_path` FROM `queue`", {("bravo",), ("charlie",)}
        )

    def test_append_partial_chunks(self):
        self.fetchers_path.mkdir()
        self.write_fetcher("f1.100.txt.part", "al")
        with self.supervisor():
            self.write_fetcher("f1.100.txt.part", "pha 0 1\n")
            tick()
            self.assertDBContents(
                "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
                {(1, "alpha", "0 1")},
            )
            self.write_fetcher("f1.100.txt.part", "bra")
            tick()
            self.write_fetcher("f1.100.txt.part", "vo ")
            tick()
            self.write_fetcher("f1.100.txt.part", "0 1")
            tick()
            self.assertDBContents(
                "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
                {(1, "alpha", "0 1")},
            )
            self.write_fetcher("f1.100.txt.part", "\n")

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(1, "alpha", "0 1"), (1, "bravo", "0 1")},
        )

    def test_delete_between_runs(self):
        with self.supervisor():
            self.write_fetcher("f1.100.txt", "alpha 0 1\n")
            self.write_fetcher("f2.101.txt", "bravo 0 1\n")

        self.fetcher("f1.100.txt").unlink()

        with self.supervisor():
            pass

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(2, "bravo", "0 1")},
        )

    def test_replace_between_runs(self):
        with self.supervisor():
            self.write_fetcher("f1.100.txt", "alpha 0 1\n")
            tick()
            self.write_fetcher("f2.101.txt", "bravo 0 1\n")

        self.fetcher("f1.100.txt").unlink()
        self.write_fetcher("f1.102.txt", "charlie 0 1\n")

        with self.supervisor():
            pass

        self.assertDBContents(
            "SELECT `fetcher_id`, `fetcher_run_started`, `attr_path`, `payload` FROM `queue`",
            {(2, 101, "bravo", "0 1"), (1, 102, "charlie", "0 1")},
        )

    def test_append_between_runs(self):
        with self.supervisor():
            self.write_fetcher("f1.100.txt.part", "alpha 0 1\n")

        self.write_fetcher("f1.100.txt.part", "bravo 0 1\n")

        with self.supervisor():
            pass

        self.assertDBContents(
            "SELECT `fetcher_id`, `attr_path`, `payload` FROM `queue`",
            {(1, "alpha", "0 1"), (1, "bravo", "0 1")},
        )

    def test_worker_empty(self):
        with self.supervisor():
            msg = self.worker_request(supervisor.READY)
            self.assertEqual(msg, supervisor.NOJOBS)

    def test_worker(self):
        self.fetchers_path.mkdir()
        self.write_fetcher(
            "f1.100.txt.part", "\n".join(["alpha 0 1", "bravo 0 1", "charlie 0 1", ""])
        )
        self.write_fetcher(
            "f2.100.txt.part",
            "\n".join(["alpha 0.1 1.0", "charlie 3.0 3.1", "delta 0.2 0.2.1", ""]),
        )

        with self.supervisor():
            with self.connect() as conn:
                conn.execute(
                    """
                    INSERT INTO `log` (`attr_path`, `started`, `finished`, `exit_code`)
                    VALUES
                        ('alpha', 100, 105, 0),
                        ('bravo', 120, 125, 0),
                        ('charlie', 110, 115, 1)
                    """
                )
            msg = self.worker_request(supervisor.READY)
            self.assertEqual(msg, supervisor.JOB + b"delta 0.2 0.2.1\n")
            msg = self.worker_request(supervisor.READY)
            self.assertTrue(msg.startswith(supervisor.JOB + b"alpha "))
            msg = self.worker_request(supervisor.READY)
            self.assertTrue(msg.startswith(supervisor.JOB + b"charlie "))
            msg = self.worker_request(supervisor.DONE + b"delta 1\n")
            self.assertTrue(msg.startswith(supervisor.JOB + b"bravo "))
            msg = self.worker_request(supervisor.DONE + b"charlie 0\n")
            self.assertTrue(msg.startswith(supervisor.JOB + b"charlie "))
            msg = self.worker_request(supervisor.DONE + b"bravo 0\n")
            self.assertEqual(msg, supervisor.NOJOBS)
            self.write_fetcher("f1.100.txt.part", "echo 0 1\n")
            msg = self.worker_request(supervisor.DONE + b"charlie 0\n")
            self.assertEqual(msg, supervisor.JOB + b"echo 0 1\n")

        self.assertDBContents(
            "SELECT `attr_path`, `exit_code` FROM `log`",
            {
                ("alpha", None),
                ("bravo", 0),
                ("charlie", 0),
                ("delta", 1),
                ("echo", None),
            },
        )


if __name__ == "__main__":
    unittest.main()
