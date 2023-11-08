# PostgreSQL testing ENV

## Prequisite

As prerequisite, you need [asdf](https://asdf-vm.com/) installed, up-to-date (`asdf update`).

Then all needed plugins installed also (`cat .tool-versions | egrep -v "^ *#" | cut -d ' ' -f 1 | xargs -L 1 echo asdf plugin-add`).

And finally, all awaited versions installed: `asdf install`

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
