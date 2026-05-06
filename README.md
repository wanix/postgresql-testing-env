# PostgreSQL testing ENV

## Prerequisite

As prerequisite, you need [mise-en-place](https://mise.jdx.dev/) installed, up-to-date.

```bash
mise trust
mise install
mise tasks ls
```

## Quickstart

```bash
mise run start
mise run client
```

To stop temporarly the cluster:

```bash
mise run stop
```

To delete the cluster but keep the configuration for next start:

```bash
mise run deleteCluster
```

To drop everything (you may have to do some sudo removal due to container ownership):

```bash
mise run mrproper
```

## External doc or code

- <https://github.com/cloudnative-pg/cloudnative-pg>
- <https://cloudnative-pg.io/releases/>
- <https://github.com/cloudnative-pg/charts/tree/main/charts>
- <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack>
- <https://mise.jdx.dev/getting-started.html>
- <https://www.postgresql.org/docs/current/pgbench.html>
