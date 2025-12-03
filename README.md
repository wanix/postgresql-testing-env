# PostgreSQL testing ENV

## Prequisite

As prerequisite, you need [mise-en-place](https://mise.jdx.dev/) installed, up-to-date.

## Quickstart

```bash
make start
make client
```

To stop temporarly the cluster:

```bash
make stop
```

To delete the cluster but keep the configuration for next start:

```bash
make deleteCluster
```

To drop everything (you may have to do some sudo removal due to container ownership):

```bash
make mrproper
```

## Building a specific PostgreSQL version needed

To build a new version of PostgreSQL, run this action: https://github.com/wanix/postgres-containers/actions/workflows/main.yml

Example:

- Postgres version: 17.5
- Postgres extensions to install: "hypopg hll cron"
- TimescaleDB version: 2.11.0  # needed only if you install timescale extension

## External doc or code

- <https://github.com/cloudnative-pg/cloudnative-pg>
- <https://cloudnative-pg.io/releases/>
- <https://github.com/cloudnative-pg/charts/tree/main/charts>
