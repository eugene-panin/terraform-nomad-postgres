# Changelog

## v0.1.0

- A shared PostgreSQL on a Nomad platform: one job, its data in a dynamic host
  volume the platform's backup copies by name, `meta.backup = "stop"` so it is
  stopped while copied.
- A Consul service other apps reach it by. It binds only the internal host
  network — a shared database is never on the public network.
- The superuser password is generated and kept in Vault. The server knows
  nothing about the databases on it: each consumer app reads the superuser
  credential and creates its own role and database.
