#!/usr/bin/env python3

r"""
Usage: supervisor.py <database_file> <input_dir> <worker_socket>

This script has two responsibilities:

  * Watch all files in a directory for tasks to give to workers, and
    store those tasks in a priority queue.

  * Listen for requests from workers and hand out tasks.

The input directory is expected to contain files conforming to the
following:

  * The name of the file must match [^.]+\.[0-9]+\.txt(\.part)?

  * The numeric part of the file name should be an integer that
    increases whenever the file is recreated (such as the current Unix
    time, but the supervisor doesn't require that).

  * The .part suffix should be present if data is still being written
    to that file. When the file is complete, it should be renamed to
    lose the .part suffix.

  * The file should consist of lines that look like

    attribute_path old_ver new_ver optional_url

    (though in reality, the supervisor only cares that there are at
    least two fields; everything past the first space is passed on
    to the workers without the supervisor getting involved).

These files are produced by fetcher processes, and are referred to
as fetcher files or fetcher runs throughout this script.

Tasks are distributed to workers based on how recently a task
corresponding to the same attribute path has been dispatched. Brand
new attribute paths are given highest priority; attribute paths that
have run most recently are given lowest priority.

The worker socket is a Unix stream socket that uses a line-based
protocol for communication. The following commands are expected:

    READY
    DONE <attribute_path> <exit_code>

The possible responses to either command are:

    NOJOBS
    JOB <attribute_path> <rest_of_line>

When a worker receives NOJOBS, it is expected to wait some period of
time before asking for jobs again (with READY).

When a worker receives JOB, it is expected to complete that job and
then send a new DONE request to get the next job.

This code has a unit test suite in supervisor_test.py.
"""

import asyncio
import contextlib
import functools
import hashlib
import os
import pathlib
import sqlite3
import sys
import time
from collections.abc import Callable, Generator, Iterable
from typing import (
    Concatenate,
    ParamSpec,
    Protocol,
    TextIO,
    TypeVar,
    overload,
)

import asyncinotify

P = ParamSpec("P")
S = TypeVar("S")
T = TypeVar("T")
A_co = TypeVar("A_co", covariant=True)
B_co = TypeVar("B_co", covariant=True)
StorageSelf = TypeVar("StorageSelf", bound="Storage")


class Wrapped(Protocol[A_co, B_co]):
    """Protocol for result of `functools.wraps`"""

    @property
    def __wrapped__(self) -> A_co: ...

    @property
    def __call__(self) -> B_co: ...


CurMethod = Callable[Concatenate[S, sqlite3.Cursor, P], T]
WrappedCurMethod = Wrapped[CurMethod[S, P, T], Callable[P, T]]


READY = b"READY\n"
DONE = b"DONE "
JOB = b"JOB "
NOJOBS = b"NOJOBS\n"


def jitter_hash(data: str) -> int:
    """
    Deterministically produce a 32-bit integer from a string, not correlated
    with the sort order of the string.

    The implementation shouldn't matter but if it ever changes, the database
    queue will need to be recreated.
    """
    h = hashlib.md5(data.encode(), usedforsecurity=False)
    return int.from_bytes(h.digest()[:4], byteorder="little", signed=True)


class Storage:
    """
    Abstracts over the database that stores the supervisor state.

    This state comprises three tables: `fetcher_runs`, `queue`, and
    `log`. (A fourth table, `fetchers`, is just a simple string
    deduplication table for fetcher names.) The `fetcher_runs` table is
    a record of the distinct fetcher files captured in the database. The
    `log` table stores the times and exit code associated with the last
    job dispatched for each attribute path. The `queue` table is the
    most interesting; it stores the contents of the fetcher files along
    with a bit indicating if that item has been dispatched to a worker.

    The `dequeue` operation has sub-linear performance only because the
    `queue_order_index` index on `queue` aligns with the query used by
    `dequeue`. This index relies on a denormalized column
    `last_started`, which is populated from `log`.`started` via the
    triggers `queue_insert_started`, `log_insert_started`, and
    `log_update_started`.
    """

    def __init__(self, conn: sqlite3.Connection):
        self._conn = conn

    @overload
    @staticmethod
    def _cursor_method(
        fun: CurMethod[StorageSelf, P, T],
    ) -> WrappedCurMethod[StorageSelf, P, T]: ...

    @overload
    @staticmethod
    def _cursor_method(
        *,
        transaction: bool = False,
    ) -> Callable[
        [CurMethod[StorageSelf, P, T]], WrappedCurMethod[StorageSelf, P, T]
    ]: ...

    # NOTE: mypy <1.6 claims this implementation doesn't match the first
    # overload; it's wrong.
    @staticmethod
    def _cursor_method(
        fun: CurMethod[StorageSelf, P, T] | None = None,
        transaction: bool = False,
    ) -> (
        WrappedCurMethod[StorageSelf, P, T]
        | Callable[[CurMethod[StorageSelf, P, T]], WrappedCurMethod[StorageSelf, P, T]]
    ):
        def decorator(
            fun: CurMethod[StorageSelf, P, T],
        ) -> WrappedCurMethod[StorageSelf, P, T]:
            if transaction:

                def wrapper(self: StorageSelf, *args: P.args, **kwargs: P.kwargs) -> T:
                    with self._conn:
                        with contextlib.closing(self._conn.cursor()) as cur:
                            cur.execute("BEGIN")
                            return fun(self, cur, *args, **kwargs)

            else:

                def wrapper(self: StorageSelf, *args: P.args, **kwargs: P.kwargs) -> T:
                    with contextlib.closing(self._conn.cursor()) as cur:
                        return fun(self, cur, *args, **kwargs)

            return functools.wraps(fun)(wrapper)  # type: ignore

        return decorator if fun is None else decorator(fun)

    @_cursor_method
    def upgrade(self, cur: sqlite3.Cursor, version: int = 2) -> None:
        """
        Create or update the database schema.

        The database stores a version number to allow for future schema
        modifications. This function contains scripts for migrating to
        each version number from its immediate predecessor. Every script
        from the current database version to the target version is run.

        For testing purposes, the optional `version` parameter can be
        used to create a database at an earlier version of the schema.

        The `Storage` class documentation explains the current schema.
        """

        cur.execute("PRAGMA user_version")
        user_version = cur.fetchone()[0]
        if user_version < 1 <= version:
            # Here is as good a place as any: we're using backtick quotation
            # extensively in these statements as a way to protect against
            # having a token mistaken for a keyword. The standard SQL quotation
            # style for this purpose is double-quote, which SQLite supports,
            # but SQLite also interprets double-quoted identifiers as strings
            # if they are in a position where an identifier isn't expected;
            # this can suppress or obfuscate error messages when one has made a
            # syntax error. Backticks are nonstandard but used in MySQL and
            # supported by SQLite, and SQLite doesn't try to interpret
            # backtick-quoted tokens as anything other than identifiers.
            cur.executescript(
                """
                BEGIN;

                CREATE TABLE `fetchers` (
                    `fetcher_id` `integer` PRIMARY KEY AUTOINCREMENT,
                    `name` `text` NOT NULL UNIQUE
                ) STRICT;

                CREATE TABLE `fetcher_runs` (
                    `fetcher_id` `integer` NOT NULL REFERENCES `fetchers` (`fetcher_id`),
                    `run_started` `integer` NOT NULL,
                    `is_complete` `integer` NOT NULL DEFAULT 0,
                    PRIMARY KEY (`fetcher_id`, `run_started`)
                ) STRICT;

                CREATE INDEX `fetcher_run_started_index`
                ON `fetcher_runs` (`run_started`, `fetcher_id`);

                CREATE TRIGGER `fetcher_runs_delete`
                AFTER DELETE
                ON `fetcher_runs`
                BEGIN
                    DELETE FROM `fetchers`
                    WHERE `fetcher_id` = OLD.`fetcher_id`
                    AND (
                        SELECT `fetcher_id`
                        FROM `fetcher_runs`
                        WHERE `fetcher_id` = OLD.`fetcher_id`
                    ) IS NULL;
                END;

                CREATE TABLE `queue` (
                    `fetcher_id` `integer` NOT NULL,
                    `fetcher_run_started` `integer` NOT NULL,
                    `attr_path` `text` NOT NULL,
                    `payload` `text` NOT NULL,
                    `is_dequeued` `integer` NOT NULL DEFAULT 0,
                    `last_started` `integer`,
                    PRIMARY KEY (`fetcher_run_started`, `fetcher_id`, `attr_path`),
                    FOREIGN KEY (`fetcher_id`, `fetcher_run_started`)
                        REFERENCES `fetcher_runs` (`fetcher_id`, `run_started`)
                        ON DELETE CASCADE
                ) STRICT;

                CREATE INDEX `queue_order_index`
                ON `queue` (
                    `last_started` ASC,
                    `attr_path`,
                    `fetcher_id`,
                    `fetcher_run_started` DESC
                );

                CREATE INDEX `queue_attr_path_index`
                ON `queue` (`attr_path` ASC);

                CREATE TABLE `log` (
                    `attr_path` `text` PRIMARY KEY,
                    `started` `integer` NOT NULL,
                    `finished` `integer`,
                    `exit_code` `integer`
                ) STRICT, WITHOUT ROWID;

                CREATE TRIGGER `queue_insert_started`
                AFTER INSERT
                ON `queue`
                BEGIN
                    UPDATE `queue` SET
                        `last_started` = `started`
                    FROM `log`
                    WHERE
                        `log`.`attr_path` = NEW.`attr_path` AND
                        `queue`.`rowid` = NEW.`rowid`;
                END;

                CREATE TRIGGER `log_insert_started`
                AFTER INSERT
                ON `log`
                BEGIN
                    UPDATE `queue` SET
                        `last_started` = NEW.`started`
                    WHERE `queue`.`attr_path` = NEW.`attr_path`;
                END;

                CREATE TRIGGER `log_update_started`
                AFTER UPDATE OF `started`
                ON `log`
                BEGIN
                    UPDATE `queue` SET
                        `last_started` = NEW.`started`
                    WHERE `queue`.`attr_path` = NEW.`attr_path`;
                END;

                COMMIT;
                """
            )
        if user_version < 2 <= version:
            # We want to add some disorder to the initial order of packages;
            # dispatching packages that are alphabetically adjacent increases
            # the chances of parallel duplicates or getting stuck on a large
            # block of time-consuming packages.
            #
            # Unfortunately, to apply this jitter retroactively we need to
            # delete most of the rows already in the database.
            cur.executescript(
                """
                BEGIN;

                DELETE FROM `fetcher_runs`;
                DELETE FROM `log`;

                ALTER TABLE `queue`
                ADD COLUMN `order_jitter` `integer`;

                DROP INDEX `queue_order_index`;

                CREATE INDEX `queue_order_index`
                ON `queue` (
                    `last_started` ASC,
                    `order_jitter`,
                    `attr_path`,
                    `fetcher_id`,
                    `fetcher_run_started` DESC
                );

                COMMIT;
                """
            )
        cur.execute(f"PRAGMA user_version = {version}")

    @_cursor_method
    def get_fetcher_runs(self, cur: sqlite3.Cursor) -> dict[tuple[str, int], bool]:
        """Return a set of fetcher runs known to the database."""
        cur.execute(
            """
            SELECT `name`, `run_started`, `is_complete`
            FROM `fetchers`
            JOIN `fetcher_runs` USING (`fetcher_id`)
            """
        )
        return {(r[0], r[1]): r[2] for r in cur}

    @_cursor_method
    def delete_fetcher_run(
        self, cur: sqlite3.Cursor, fetcher: str, run_started: int
    ) -> None:
        """Delete a fetcher run and all of its queue items."""
        cur.execute(
            """
            DELETE FROM `fetcher_runs`
            WHERE `fetcher_id` = (SELECT `fetcher_id` FROM `fetchers` WHERE `name` = ?)
            AND `run_started` = ?
            """,
            (fetcher, run_started),
        )

    @_cursor_method(transaction=True)
    def delete_fetcher_runs(
        self, cur: sqlite3.Cursor, fetchers: Iterable[tuple[str, int]]
    ) -> None:
        """Delete multiple fetcher runs and their queue items."""
        for fetcher, run_started in fetchers:
            self.delete_fetcher_run.__wrapped__(self, cur, fetcher, run_started)

    @_cursor_method(transaction=True)
    def upsert_fetcher_run(
        self,
        cur: sqlite3.Cursor,
        fetcher: str,
        run_started: int,
        is_complete: bool,
    ) -> None:
        """Add or update a fetcher."""
        cur.execute("INSERT OR IGNORE INTO `fetchers` (`name`) VALUES (?)", (fetcher,))
        cur.execute(
            """
            INSERT INTO `fetcher_runs` (`fetcher_id`, `run_started`, `is_complete`)
            VALUES ((SELECT `fetcher_id` FROM `fetchers` WHERE `name` = ?), ?, ?)
            ON CONFLICT DO UPDATE SET `is_complete` = excluded.`is_complete`
            """,
            (fetcher, run_started, is_complete),
        )

    @_cursor_method(transaction=True)
    def enqueue(
        self,
        cur: sqlite3.Cursor,
        fetcher: str,
        run_started: int,
        entries: list[tuple[str, str]],
    ) -> None:
        """
        Add entries for a given fetcher to the queue.

        The same attribute paths can appear multiple times in the queue
        with different payloads, but only once per fetcher run. Fetcher
        files shouldn't contain more than one line for a given attribute
        path, but if they do, the later line overwrites the earlier one.
        """
        cur.executemany(
            """
            INSERT INTO `queue` (`fetcher_id`, `fetcher_run_started`, `attr_path`, `payload`, `order_jitter`)
            SELECT `fetcher_id`, ?, ?, ?, ?
            FROM `fetchers`
            WHERE `name` = ?
            ON CONFLICT DO UPDATE SET `payload` = excluded.`payload`
            """,
            ((run_started, a, p, jitter_hash(a), fetcher) for a, p in entries),
        )

    @_cursor_method(transaction=True)
    def dequeue(self, cur: sqlite3.Cursor, start_time: int) -> tuple[str, str] | None:
        """
        Pull one entry from the top of the queue.

        Returns a tuple (attribute path, payload), or None if nothing is
        currently available in the queue. If an entry is dequeued, a log
        record for this entry will be marked as started as of
        `start_time`.

        Most of the time, if a job for an attribute path was started but
        has not yet finished, any queue entries for that same path will
        be skipped. However, in case a worker dies or fails to report
        back, after 12 hours such entries are eligible again.
        `start_time` is used to determine if this 12-hour exclusion
        period has ended. (These details are only likely to be relevant
        when the queue is very small, like at the beginning or the end
        of a run.)
        """
        cur.execute(
            """
            SELECT
                `fetcher_id`,
                `attr_path`,
                `payload`
            FROM `queue`
            LEFT JOIN `log` USING (`attr_path`)
            GROUP BY `last_started`, `order_jitter`, `attr_path`, `fetcher_id`
            HAVING `is_dequeued` = 0
            AND (`started` IS NULL OR `finished` IS NOT NULL OR `started` + 43200 < ?)
            AND (TRUE OR `max`(`fetcher_run_started`))
            ORDER BY `last_started` ASC, `order_jitter`, `attr_path`, `fetcher_id`
            LIMIT 1
            """,
            (start_time,),
        )
        # NOTE: The `max` call in the above query triggers a nonstandard SQLite
        # behavior; see <https://www.sqlite.org/lang_select.html#bareagg>.
        # This behavior is critical to the correctness of this query. We don't
        # actually need the value of `max`(), though, so we tuck it into the
        # HAVING clause in a position where it can't have any other effect.

        row: tuple[int, str, str] | None = cur.fetchone()
        result = None
        if row is not None:
            fetcher_id, attr_path, payload = row
            cur.execute(
                """
                UPDATE `queue` SET `is_dequeued` = 1
                WHERE `fetcher_id` = ? AND `attr_path` = ?
                """,
                (fetcher_id, attr_path),
            )
            cur.execute(
                """
                INSERT INTO `log` (`attr_path`, `started`) VALUES (?, ?)
                ON CONFLICT DO UPDATE SET
                    `started` = excluded.`started`,
                    `finished` = NULL,
                    `exit_code` = NULL
                """,
                (attr_path, start_time),
            )
            result = attr_path, payload
        return result

    @_cursor_method
    def finish(
        self, cur: sqlite3.Cursor, attr_path: str, finish_time: int, exit_code: int
    ) -> None:
        """Log the completion of a dequeued entry."""
        cur.execute(
            "UPDATE `log` SET `finished` = ?, `exit_code` = ? WHERE `attr_path` = ?",
            (finish_time, exit_code, attr_path),
        )


async def listen_for_workers(storage: Storage, socket_path: pathlib.Path) -> None:
    """Open a Unix stream socket and handle requests from workers."""

    async def worker_connected(
        reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        try:
            while True:
                line = await reader.readline()
                if line == b"":
                    break
                now = int(time.time())
                do_dequeue = False
                if line == READY:
                    do_dequeue = True
                elif line.startswith(DONE):
                    parts = line.split(b" ")
                    attr_path = parts[1].decode()
                    exit_code = int(parts[2])
                    storage.finish(attr_path, now, exit_code)
                    do_dequeue = True
                else:
                    print(f"Unexpected command from worker: {line!r}")
                    break

                if do_dequeue:
                    entry = storage.dequeue(now)
                    if entry:
                        writer.write(
                            b"".join(
                                [
                                    JOB,
                                    entry[0].encode(),
                                    b" ",
                                    entry[1].encode(),
                                    b"\n",
                                ]
                            )
                        )
                    else:
                        writer.write(NOJOBS)
                    await writer.drain()
        finally:
            writer.close()
            await writer.wait_closed()

    server = await asyncio.start_unix_server(worker_connected, socket_path)
    await server.serve_forever()


class FetcherDataWatcher:
    """
    Monitors a directory containing fetcher files and syncs them to
    storage.
    """

    _dir_events = asyncinotify.Mask.CREATE | asyncinotify.Mask.DELETE
    _file_events = asyncinotify.Mask.MODIFY | asyncinotify.Mask.MOVE_SELF

    class _FileDeleted(Exception):
        """A fetcher file was deleted."""

    class _FileMoved(Exception):
        """A fetcher file was moved."""

    def __init__(
        self,
        storage: Storage,
        fetcher_data_path: pathlib.Path,
        inotify: asyncinotify.Inotify,
    ) -> None:
        self._storage = storage
        self._fetcher_data_path = fetcher_data_path
        self._inotify = inotify
        self._gtors: dict[tuple[str, int], Generator[None, None, None]] = {}

    async def watch(self) -> None:
        """Start the watcher."""

        self._inotify.add_watch(self._fetcher_data_path, self._dir_events)

        try:
            known_fetcher_runs = self._storage.get_fetcher_runs()
            for path in self._fetcher_data_path.iterdir():
                if (that := self._parse_fetcher_filename(path.name)) is None:
                    continue
                name, run_started, is_complete = that
                if not known_fetcher_runs.pop((name, run_started), False):
                    self._on_fetcher(path, name, run_started, is_complete)
            self._storage.delete_fetcher_runs(known_fetcher_runs.keys())

            async for event in self._inotify:
                if event.path is None:
                    continue
                if (that := self._parse_fetcher_filename(event.path.name)) is None:
                    continue
                name, run_started, is_complete = that
                with contextlib.suppress(KeyError):
                    match event.mask:
                        case asyncinotify.Mask.CREATE:
                            self._on_fetcher(event.path, name, run_started, is_complete)
                        case asyncinotify.Mask.DELETE:
                            if not is_complete:
                                self._close_fetcher(
                                    name, run_started, self._FileDeleted()
                                )
                            self._storage.delete_fetcher_run(name, run_started)
                        case asyncinotify.Mask.MODIFY:
                            self._gtors[(name, run_started)].send(None)
                        case asyncinotify.Mask.MOVE_SELF:
                            self._close_fetcher(name, run_started, self._FileMoved())
        finally:
            with contextlib.suppress(KeyError):
                while True:
                    self._gtors.popitem()[1].close()

    def _on_fetcher(
        self,
        path: pathlib.Path,
        name: str,
        run_started: int,
        is_complete: bool,
    ) -> None:
        watch = None
        try:
            if not is_complete:
                watch = self._inotify.add_watch(path, self._file_events)
            file = path.open(encoding="utf-8")
        except FileNotFoundError:
            return
        self._storage.upsert_fetcher_run(name, run_started, is_complete)
        gtor = self._read_fetcher_file(file, watch, name, run_started)
        gtor.send(None)
        if is_complete:
            gtor.close()
        else:
            self._gtors[(name, run_started)] = gtor

    def _close_fetcher(self, name: str, run_started: int, ex: Exception) -> None:
        with contextlib.suppress(StopIteration):
            self._gtors.pop((name, run_started)).throw(ex)

    def _parse_fetcher_filename(self, name: str) -> tuple[str, int, bool] | None:
        match name.split("."):
            case [stem, run_started, "txt", "part"]:
                return stem, int(run_started), False
            case [stem, run_started, "txt"]:
                return stem, int(run_started), True
        return None

    def _read_fetcher_file(
        self,
        file: TextIO,
        watch: asyncinotify.Watch | None,
        name: str,
        run_started: int,
    ) -> Generator[None, None, None]:
        with file:
            try:
                while True:
                    self._storage.enqueue(
                        name,
                        run_started,
                        (yield from self._read_fetcher_lines(file)),
                    )
            except self._FileDeleted:
                pass
            except self._FileMoved:
                try:
                    target_path_stat = (
                        self._fetcher_data_path / f"{name}.{run_started}.txt"
                    ).stat()
                except FileNotFoundError:
                    pass
                else:
                    if target_path_stat.st_ino == os.stat(file.fileno()).st_ino:
                        for entries in self._read_fetcher_lines(file):
                            if entries is not None:
                                self._storage.enqueue(name, run_started, entries)
                            break
                        self._storage.upsert_fetcher_run(name, run_started, True)
                        assert watch is not None
                        self._inotify.rm_watch(watch)
                        return
                self._storage.delete_fetcher_run(name, run_started)

    def _read_fetcher_lines(
        self, file: TextIO
    ) -> Generator[None, None, list[tuple[str, str]]]:
        """
        Read all available complete lines from an open fetcher file.

        This is a generator, but not one that yields each line. It will
        *return* all lines as a non-empty list. If no complete lines are
        available, however, it will yield. Calling code should reenter
        the generator when more content becomes available, or use `yield
        from` to pass that responsibility outward.
        """
        entries: list[tuple[str, str]] = []
        while True:
            cookie = file.tell()
            line = file.readline()
            if line == "" or line[-1] != "\n":
                file.seek(cookie)
                if entries:
                    return entries
                yield
                continue
            match line.strip().split(" ", maxsplit=1):
                case [attr_path, payload]:
                    entries.append((attr_path, payload))
                case _:
                    print(f"Unexpected line in {file.name!r}: {line!r}")


async def main(
    db_path: pathlib.Path,
    fetcher_data_path: pathlib.Path,
    socket_path: pathlib.Path,
) -> None:
    """Run all supervisor responsibilities."""
    fetcher_data_path.mkdir(parents=True, exist_ok=True)
    with contextlib.closing(sqlite3.connect(db_path, isolation_level=None)) as conn:
        conn.execute("PRAGMA foreign_keys = ON")
        storage = Storage(conn)
        storage.upgrade()
        with asyncinotify.Inotify() as inotify:
            watcher = FetcherDataWatcher(storage, fetcher_data_path, inotify)
            await asyncio.gather(
                listen_for_workers(storage, socket_path),
                watcher.watch(),
            )


if __name__ == "__main__":
    asyncio.run(main(*[pathlib.Path(arg) for arg in sys.argv[1:4]]))
