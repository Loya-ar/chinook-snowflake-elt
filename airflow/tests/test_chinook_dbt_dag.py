"""DAG integrity tests: the DAG imports cleanly and is wired as intended."""

from datetime import timedelta
from pathlib import Path

import pytest

try:  # Airflow 3.1+
    from airflow.dag_processing.dagbag import DagBag
except ImportError:
    from airflow.models import DagBag

DAGS_DIR = Path(__file__).resolve().parents[1] / "dags"
EXPECTED_ORDER = ["dbt_seed", "dbt_run", "dbt_test", "check_row_count", "publish_success"]


@pytest.fixture(scope="module")
def dagbag():
    # Example DAGs are off via AIRFLOW__CORE__LOAD_EXAMPLES=false (see the CI workflow).
    return DagBag(dag_folder=str(DAGS_DIR))


@pytest.fixture(scope="module")
def dag(dagbag):
    return dagbag.dags["chinook_dbt"]


def test_no_import_errors(dagbag):
    assert dagbag.import_errors == {}
    assert list(dagbag.dags) == ["chinook_dbt"]


def test_task_order_is_a_straight_line(dag):
    assert set(dag.task_ids) == set(EXPECTED_ORDER)
    for upstream, downstream in zip(EXPECTED_ORDER, EXPECTED_ORDER[1:]):
        assert dag.get_task(upstream).downstream_task_ids == {downstream}
    assert dag.get_task("dbt_seed").upstream_task_ids == set()


def test_quality_gate_uses_all_success(dag):
    # Downstream tasks only run when everything before them succeeded,
    # so a failed dbt_test stops check_row_count and publish_success.
    for task_id in EXPECTED_ORDER[1:]:
        assert dag.get_task(task_id).trigger_rule == "all_success"


def test_schedule_and_retries(dag):
    assert dag.schedule == "@daily"
    assert dag.catchup is False
    for task in dag.tasks:
        assert task.retries == 2
        assert task.retry_delay == timedelta(minutes=5)
        assert task.on_failure_callback


def test_dbt_tasks_pass_profiles_dir(dag):
    for task_id in ["dbt_seed", "dbt_run", "dbt_test"]:
        command = dag.get_task(task_id).bash_command
        assert f"dbt {task_id.removeprefix('dbt_')} --profiles-dir ." in command
