"""Write Prometheus textfile metrics from the supervisor's state.db."""

import sqlite3
import sys
import time
from pathlib import Path

HOUR = 3600
# worker.bash runs each job under `timeout 6h`; older unfinished rows were
# killed by a restart and never got an exit code
JOB_TIMEOUT = 6 * HOUR


def render(conn: sqlite3.Connection, now: int) -> str:
    lines: list[str] = []

    def metric(name: str, kind: str, help_: str) -> None:
        lines.append(f"# HELP {name} {help_}")
        lines.append(f"# TYPE {name} {kind}")

    metric("nixpkgs_update_queue_length", "gauge", "Packages waiting to be updated")
    (queued,) = conn.execute(
        "SELECT count(*) FROM queue WHERE is_dequeued = 0"
    ).fetchone()
    lines.append(f"nixpkgs_update_queue_length {queued}")

    metric("nixpkgs_update_jobs_running", "gauge", "Jobs started but not finished")
    (running,) = conn.execute(
        "SELECT count(*) FROM log WHERE finished IS NULL AND started >= ?",
        (now - JOB_TIMEOUT,),
    ).fetchone()
    lines.append(f"nixpkgs_update_jobs_running {running}")

    metric(
        "nixpkgs_update_jobs_finished_1h",
        "gauge",
        "Jobs finished in the last hour by exit code",
    )
    for exit_code, count in conn.execute(
        "SELECT exit_code, count(*) FROM log WHERE finished >= ? GROUP BY exit_code",
        (now - HOUR,),
    ):
        lines.append(
            f'nixpkgs_update_jobs_finished_1h{{exit_code="{exit_code}"}} {count}'
        )

    (last_finished,) = conn.execute("SELECT max(finished) FROM log").fetchone()
    if last_finished is not None:
        metric(
            "nixpkgs_update_last_job_finished_timestamp_seconds",
            "gauge",
            "When the last job finished",
        )
        lines.append(
            f"nixpkgs_update_last_job_finished_timestamp_seconds {last_finished}"
        )

    metric(
        "nixpkgs_update_fetcher_last_complete_run_timestamp_seconds",
        "gauge",
        "Start of the last complete fetcher run",
    )
    for name, started in conn.execute(
        """
        SELECT name, max(run_started) FROM fetcher_runs
        JOIN fetchers USING (fetcher_id)
        WHERE is_complete = 1 GROUP BY name
        """
    ):
        lines.append(
            "nixpkgs_update_fetcher_last_complete_run_timestamp_seconds"
            f'{{fetcher="{name}"}} {started}'
        )

    return "\n".join(lines) + "\n"


def main() -> None:
    db_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    text = render(conn, int(time.time()))
    # node-exporter must never see a half-written file
    tmp = out_path.with_suffix(".tmp")
    tmp.write_text(text)
    tmp.replace(out_path)


if __name__ == "__main__":
    main()
