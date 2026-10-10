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

## v0.1.1

- The task reserves 768 MB, sized to its use, and may grow to 2048 MB:
  `resources.memory_max` (Nomad memory oversubscription, which the platform
  turns on). It reserved more than it used before.

## v0.1.2

- `mesh`: PostgreSQL can join the Consul service mesh — an Envoy sidecar with the
  transparent proxy, so mesh services reach it as `<job_name>.virtual.consul` over
  mTLS and only those in `mesh.allow` may (service-intentions; the platform's ACLs
  deny the rest). `mesh.keep_open_ports` stay reachable outside the mesh while
  clients move in. Envoy's metrics are a `<job_name>-envoy` service tagged for
  the platform's Alloy, for Consul's topology.

## v0.1.3

- In the mesh the health check is `pg_isready` inside the container: Nomad takes
  no tcp check on a service in the mesh (v0.1.2 could not be applied with it on).

## v0.1.4

- In the mesh Envoy runs as uid 1337 (an app on Envoy's default uid bypassed the mesh); the intentions entry exists only when some service is allowed.
