import sqlite3
import unittest

import metrics

NOW = 1_000_000


def make_db() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.executescript(
        """
        CREATE TABLE fetchers (fetcher_id integer PRIMARY KEY, name text);
        CREATE TABLE fetcher_runs (
            fetcher_id integer, run_started integer, is_complete integer
        );
        CREATE TABLE queue (
            fetcher_id integer, fetcher_run_started integer, attr_path text,
            payload text, is_dequeued integer, last_started integer
        );
        CREATE TABLE log (
            attr_path text PRIMARY KEY, started integer,
            finished integer, exit_code integer
        );
        """
    )
    return conn


class MetricsTest(unittest.TestCase):
    def test_empty_database(self) -> None:
        out = metrics.render(make_db(), NOW)
        self.assertIn("nixpkgs_update_queue_length 0\n", out)
        self.assertIn("nixpkgs_update_jobs_running 0\n", out)
        self.assertNotIn("nixpkgs_update_last_job_finished_timestamp_seconds", out)

    def test_jobs_are_bucketed_by_exit_code_within_the_last_hour(self) -> None:
        conn = make_db()
        conn.executemany(
            "INSERT INTO log VALUES (?, ?, ?, ?)",
            [
                ("a", NOW - 100, NOW - 90, 0),
                ("b", NOW - 200, NOW - 150, 1),
                ("c", NOW - 300, NOW - 250, 1),
                ("old", NOW - 9000, NOW - 8000, 0),
                ("running", NOW - 10, None, None),
                ("killed-by-restart", NOW - 7 * 3600, None, None),
            ],
        )
        out = metrics.render(conn, NOW)
        self.assertIn('nixpkgs_update_jobs_finished_1h{exit_code="0"} 1\n', out)
        self.assertIn('nixpkgs_update_jobs_finished_1h{exit_code="1"} 2\n', out)
        self.assertIn("nixpkgs_update_jobs_running 1\n", out)
        self.assertIn(
            f"nixpkgs_update_last_job_finished_timestamp_seconds {NOW - 90}\n", out
        )

    def test_queue_length_ignores_dequeued_entries(self) -> None:
        conn = make_db()
        conn.executemany(
            "INSERT INTO queue VALUES (1, 1, ?, '0 1', ?, NULL)",
            [("a", 0), ("b", 0), ("c", 1)],
        )
        self.assertIn("nixpkgs_update_queue_length 2\n", metrics.render(conn, NOW))

    def test_fetcher_freshness_uses_last_complete_run(self) -> None:
        conn = make_db()
        conn.execute("INSERT INTO fetchers VALUES (1, 'github')")
        conn.executemany(
            "INSERT INTO fetcher_runs VALUES (1, ?, ?)",
            [(NOW - 5000, 1), (NOW - 100, 0)],
        )
        out = metrics.render(conn, NOW)
        self.assertIn(
            f'nixpkgs_update_fetcher_last_complete_run_timestamp_seconds{{fetcher="github"}} {NOW - 5000}\n',
            out,
        )


if __name__ == "__main__":
    unittest.main()
