import sqlite3
import time
from datetime import datetime, timezone


def get_db_connection(db_path):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def fetch_queue_data(conn):
    query = """
    SELECT
        DENSE_RANK() OVER (ORDER BY last_started ASC) AS number,
        attr_path,
        payload
    FROM
        'queue'
    ORDER BY
        last_started ASC
    """
    return conn.execute(query).fetchall()


def cycle_time(conn):
    row = conn.execute("""
    SELECT
        (MAX(finished) - MIN(started)) / 86400.0
    FROM log
    WHERE attr_path IN (
        SELECT attr_path
        FROM queue
        WHERE fetcher_id = (
            SELECT fetcher_id
            FROM fetchers
            WHERE name = 'updatescript'
        )
    )
    AND started IS NOT NULL
    AND finished IS NOT NULL
    """).fetchone()
    return "-" if row[0] is None else f"{row[0]:.1f} days"


def generate_html_table(rows):
    table_rows = "".join(
        f"""
        <tr>
            <td>{row["number"]}</td>
            <td>{row["attr_path"]}</td>
            <td>{row["payload"]}</td>
        </tr>
        """
        for row in rows
    )
    return table_rows


def export_html(db_path):
    with get_db_connection(db_path) as conn:
        results = fetch_queue_data(conn)
        cycle = cycle_time(conn)

    generated = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    html = f"""
    <html>
    <head>
        <title>nixpkgs-update queue</title>
    </head>
    <body>
        <h1>nixpkgs-update queue</h1>
        <h3>this page is updated every 15 minutes, last updated: {generated}</h3>
        <h3>cycle time: {cycle}</h3>
        <table>
            <thead>
                <tr>
                    <th>number</th>
                    <th>attribute path</th>
                    <th>payload</th>
                </tr>
            </thead>
            <tbody>
                {generate_html_table(results)}
            </tbody>
        </table>
    </body>
    </html>
    """

    with open("queue.html", "w") as f:
        f.write(html)


if __name__ == "__main__":
    DB_PATH = "state.db"
    while True:
        export_html(DB_PATH)
        time.sleep(15 * 60)
