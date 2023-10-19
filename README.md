# PostgreSQL testing ENV

## Prequisite

As prerequisite, you need [asdf](https://asdf-vm.com/) installed, up-to-date (`asdf update`).

Then all needed plugins installed also (`cat .tool-versions | egrep -v "^ *#" | cut -d ' ' -f 1 | xargs -L 1 echo asdf plugin-add`).

And finally, all awaited version installed: `asdf install`

## Quickstart

```bash
make start
make client
```

Once tests done

```bash
make clean
```
