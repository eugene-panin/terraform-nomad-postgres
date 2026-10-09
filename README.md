# terraform-nomad-postgres

A shared PostgreSQL on a Nomad platform that has Consul and Vault — such as
[hashi](https://github.com/eugene-panin/damstack-hashi). The
[damstack-postgres](https://github.com/eugene-panin/damstack-postgres) stack
wires it.

It is deliberately dumb: one PostgreSQL server, a superuser credential in Vault,
a Consul service. **It knows nothing about the databases on it.** Each consumer
app reads the superuser credential and creates its own role and database — so a
new database is the consumer's concern, never a change here.

## What it deploys

- One Nomad job, PostgreSQL, data in the `<job_name>-data` dynamic host volume
  the platform's backup copies by name (`meta.backup = "stop"`).
- A Consul service named `<job_name>` on `port`, bound to the internal host
  network. Other jobs reach it at the server's internal address on that port.
- The superuser `{username, password}` in Vault at
  `<vault_kv_path>/<namespace>/<job_name>/admin`.

## How a consumer uses it

A consumer app (e.g. `odoo` with `postgres.mode = external`) gets the server's
internal `host`, the `port`, and the Vault name of the admin credential. On
start it connects as the superuser and creates its own role and database,
idempotently. The server is never told about it.

## Inputs

| Name | Default | What |
| --- | --- | --- |
| `vault_kv_path` | — | Vault KV v2 mount the platform gives |
| `job_name` | `postgres` | Nomad job and Consul service name |
| `namespace` | `default` | Nomad namespace |
| `datacenters` | `["*"]` | Nomad datacenters |
| `image` | `postgres:16.10` | PostgreSQL image, pinned |
| `admin_user` | `postgres` | superuser name |
| `port` | `5432` | port on the internal host network |
| `internal_host_network` | `default` | host network it binds to |
| `resources` | `{500, 1024}` | `{cpu, memory}` |

## Outputs

`job_id`, `service_name`, `port`, `admin_user`, `admin_secret` (Vault name),
`data_volume`, `admin_password` (sensitive).

## Development

```sh
make lint
make module-tests
```
