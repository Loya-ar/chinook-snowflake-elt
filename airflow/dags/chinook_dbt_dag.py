"""Daily Airflow DAG that builds the Chinook dbt project on DuckDB.

    dbt_seed -> dbt_run -> dbt_test -> check_row_count -> publish_success

Every task needs the one before it to succeed (Airflow's default trigger rule),
so a failing dbt test stops the run: check_row_count and publish_success are
marked upstream_failed and never execute. That is the quality gate.

Each task retries twice, 5 minutes apart. When a task fails for the last time,
alert_on_failure() appends a JSON line (DAG, task, run date, error) to
ALERT_LOG_PATH, and posts to ALERT_WEBHOOK_URL if one is set.

Paths come from environment variables so the same file works in Docker
(the defaults) and anywhere else.
"""

from __future__ import annotations

import json
import os
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", "/opt/airflow/dbt")
# dbt lives in its own virtualenv so its dependencies cannot clash with Airflow's.
DBT_BIN = os.environ.get("DBT_BIN", "/opt/dbt-venv/bin/dbt")
DBT_PYTHON = os.environ.get("DBT_PYTHON", "/opt/dbt-venv/bin/python")
ALERT_LOG_PATH = os.environ.get("ALERT_LOG_PATH", "/opt/airflow/alerts/dbt_failures.log")
ALERT_WEBHOOK_URL = os.environ.get("ALERT_WEBHOOK_URL", "")
CHECKS_DIR = Path(__file__).parent / "checks"


def alert_on_failure(context) -> None:
    """Record a task's final failure (after all retries) in the alert log."""
    ti = context["task_instance"]
    # Manual runs in Airflow 3 have no logical date, so fall back to run_after.
    run_date = context.get("logical_date") or getattr(context.get("dag_run"), "run_after", None)
    record = {
        "alerted_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "dag_id": ti.dag_id,
        "task_id": ti.task_id,
        "run_id": context.get("run_id"),
        "run_date": run_date.isoformat() if run_date else None,
        "try_number": ti.try_number,
        "error": str(context.get("exception")),
        "log_url": getattr(ti, "log_url", None),
    }
    path = Path(ALERT_LOG_PATH)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")

    if ALERT_WEBHOOK_URL:  # optional: a Slack or Discord incoming webhook
        text = f"Airflow: {ti.dag_id}.{ti.task_id} failed for run {record['run_id']}: {record['error']}"
        body = json.dumps({"text": text, "content": text}).encode()
        req = urllib.request.Request(
            ALERT_WEBHOOK_URL, data=body, headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(req, timeout=10)
        except Exception as exc:  # the log record above is already written
            print(f"Webhook alert failed: {exc}")


def dbt(command: str) -> str:
    return f"cd {DBT_PROJECT_DIR} && {DBT_BIN} {command} --profiles-dir ."


default_args = {
    "owner": "data",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": alert_on_failure,
}

with DAG(
    dag_id="chinook_dbt",
    description="Daily dbt seed, run and test of the Chinook star schema on DuckDB",
    schedule="@daily",
    start_date=datetime(2026, 11, 1),
    catchup=False,
    max_active_runs=1,  # DuckDB allows one writer at a time
    default_args=default_args,
    tags=["dbt", "duckdb", "chinook"],
) as dag:
    dbt_seed = BashOperator(task_id="dbt_seed", bash_command=dbt("seed"))
    dbt_run = BashOperator(task_id="dbt_run", bash_command=dbt("run"))
    dbt_test = BashOperator(task_id="dbt_test", bash_command=dbt("test"))
    check_row_count = BashOperator(
        task_id="check_row_count",
        bash_command=f"{DBT_PYTHON} {CHECKS_DIR / 'row_count.py'} {DBT_PROJECT_DIR}/chinook.duckdb",
    )
    publish_success = BashOperator(
        task_id="publish_success",
        bash_command=(
            "echo \"chinook_dbt run {{ run_id }} passed: seed, run, test and row count all green\""
        ),
    )

    dbt_seed >> dbt_run >> dbt_test >> check_row_count >> publish_success
