# PostgreSQL testing ENV

## Prerequisite

As prerequisite, you need [mise-en-place](https://mise.jdx.dev/) installed, up-to-date.

```bash
mise trust
mise run init
```

## Quickstart

```bash
mise run start
mise run client
```

To prepare then run the benchs:

```bash
mise run pgbench-cleanup && mise run pgbench-init
mise run pgbench-run
```

To stop temporary the cluster:

```bash
mise run stop
```

To delete the cluster but keep the configuration for next start:

```bash
mise run infra-delete-cluster
```

To drop everything (you may have to do some sudo removal due to container ownership):

```bash
mise run mrproper
```

## Tuning cluster

You can tune the cluster or operator by changing some environment variables.

You can list them using the `lsvars` task:

```bash
mise run lsvars
```

Also using the env vars CNPG_OPERATOR_VALUES_OVERRIDE and CNPG_CLUSTER_VALUES_OVERRIDE you can provide custom helm values files to override the default ones for the operator and cluster respectively.

Example:

```bash
cat <<EOF > local-config.d/postgresql.conf.yml
cluster:
  postgresql:
    parameters:
      pg_stat_statements.max: "10000"
      pg_stat_statements.track: all
      pgaudit.log: "all, -misc"
      pgaudit.log_catalog: "off"
      pgaudit.log_parameter: "on"
      pgaudit.log_relation: "on"
EOF

cat <<EOF > local-config.d/johndoe-secret.yml
apiVersion: v1
data:
  username: $(echo -n "johndoe" | base64)
  password: $(openssl rand -base64 1024 | head -c 16 | base64)
kind: Secret
type: kubernetes.io/basic-auth
metadata:
  name: pg-user-johndoe
  labels:
    cnpg.io/reload: "true"
EOF

kubectl apply -n "${$NAMESPACE:-$(yq -Poy '.vars.NAMESPACE' mise.toml)}" -f local-config.d/johndoe-secret.yml

cat <<EOF > local-config.d/roles.yml
cluster:
  roles:
    - name: johndoe
      ensure: present
      comment: "A role for testing"
      passwordSecret:
        name: pg-user-johndoe
      login: true
      superuser: false
      inRoles:
        - pg_monitor
        - pg_read_all_data
EOF


CNPG_CLUSTER_VALUES_OVERRIDE="local-config.d/postgresql.conf.yml,local-config.d/roles.yml" \
  mise run cnpg-cluster-update
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

- <https://mise.jdx.dev/getting-started.html>
- <https://cloudnative-pg.io/docs/current/>
- <https://github.com/cloudnative-pg/cloudnative-pg>
- <https://cloudnative-pg.io/releases/>
- <https://github.com/cloudnative-pg/charts/tree/main/charts>
- <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack>
- <https://www.postgresql.org/docs/current/pgbench.html>
- <https://blog.dalibo.com/tags.html#CloudNativePG-ref>
