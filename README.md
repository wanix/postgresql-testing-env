# PostgreSQL testing ENV

## Prerequisite

As prerequisite, you need [mise-en-place](https://mise.jdx.dev/) installed, up-to-date.

```bash
mise trust
mise run init
```

## Quickstart

```bash
mise run infra-start
mise run client
```

To prepare then run the benchs:

```bash
mise run pgbench-cleanup && mise run pgbench-init
mise run pgbench-run
```

To stop temporary the cluster:

```bash
mise run infra-stop
```

To delete the cluster but keep the configuration for next start:

```bash
mise run infra-delete-cluster
```

To drop everything (you may have to do some sudo removal due to container ownership):

```bash
mise run mrproper
```

## Tuning benches

You can tune the benchs execution by setting the following environment variables:

- `NB_INSTANCES`: number of pgbench instances to run in parallel (default 1)
- `NB_CLIENTS`: number of clients to use for each pgbench instance (default
- `NB_JOBS`: number of jobs to run for each pgbench instance (default 1)
- `NB_SECONDS`: duration of each pgbench instance in seconds (default 60)
- `NB_SCALE`: scale factor to use for pgbench initialization (default 250 for around 4GB database, 1000 for around 16GB database)

Examples with tuning:

```bash
mise run pgbench-cleanup

NB_SCALE=1000 mise run pgbench-init

NB_INSTANCES=10 NB_CLIENTS=10 NB_JOBS=10 NB_SECONDS=300 mise run pgbench-run
```

## External doc or code

- <https://github.com/cloudnative-pg/cloudnative-pg>
- <https://cloudnative-pg.io/releases/>
- <https://github.com/cloudnative-pg/charts/tree/main/charts>
- <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack>
- <https://mise.jdx.dev/getting-started.html>
- <https://www.postgresql.org/docs/current/pgbench.html>
- <https://blog.dalibo.com/tags.html#CloudNativePG-ref>
