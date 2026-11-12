# Airflow image with dbt installed in its own virtualenv, so dbt's pinned
# dependencies cannot conflict with Airflow's.
FROM apache/airflow:3.3.2-python3.11

# Build context is the repo root (see docker-compose.yaml), so the image
# installs the same pinned dbt versions as local runs and CI.
COPY dbt/requirements.txt /tmp/dbt-requirements.txt

# The base image runs as the non-root "airflow" user, which cannot write to /opt.
USER root
RUN mkdir /opt/dbt-venv && chown airflow:0 /opt/dbt-venv
USER airflow

RUN python -m venv /opt/dbt-venv \
 && /opt/dbt-venv/bin/pip install --no-cache-dir -r /tmp/dbt-requirements.txt
