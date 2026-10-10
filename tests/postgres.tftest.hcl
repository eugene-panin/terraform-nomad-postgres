mock_provider "consul" {}
mock_provider "nomad" {}
mock_provider "random" {}
mock_provider "vault" {}

variables {
  vault_kv_path = "secret"
}

run "it_exposes_a_consul_service" {
  command = apply

  assert {
    condition     = output.service_name == "postgres" && output.port == 5432
    error_message = "PostgreSQL is not exposed as the expected Consul service and port."
  }

  assert {
    condition     = output.admin_secret == "default/postgres/admin"
    error_message = "The admin credential is not at the expected Vault path."
  }
}

run "it_binds_the_internal_network_only" {
  command = apply

  assert {
    condition     = strcontains(nomad_job.postgres.jobspec, "host_network = \"default\"")
    error_message = "PostgreSQL is not on the internal host network."
  }

  assert {
    condition     = !strcontains(nomad_job.postgres.jobspec, "host_network = \"public\"")
    error_message = "A shared database must never bind the public host network."
  }

  assert {
    condition     = !strcontains(nomad_job.postgres.jobspec, "traefik.enable")
    error_message = "PostgreSQL is a backend service; it must not be routed by Traefik."
  }
}

run "memory_is_reserved_by_use_and_may_grow" {
  command = apply

  assert {
    condition     = strcontains(nomad_job.postgres.jobspec, "memory     = 768") && strcontains(nomad_job.postgres.jobspec, "memory_max = 2048")
    error_message = "The task must reserve its usual memory and be allowed to grow to memory_max."
  }
}

run "it_joins_the_mesh" {
  command = apply

  variables {
    mesh = { enabled = true, allow = ["odoo", "sauron-ui"], keep_open_ports = [5432] }
  }

  assert {
    condition = (
      strcontains(nomad_job.postgres.jobspec, "transparent_proxy")
      && strcontains(nomad_job.postgres.jobspec, "exclude_inbound_ports = [\"5432\",\"9102\"]")
      && strcontains(nomad_job.postgres.jobspec, "name     = \"postgres-envoy\"")
      && strcontains(nomad_job.postgres.jobspec, "command  = \"pg_isready\"")
      && !strcontains(nomad_job.postgres.jobspec, "type     = \"tcp\"")
      && strcontains(nomad_job.postgres.jobspec, "uid                   = \"1337\"")
    )
    error_message = "In the mesh PostgreSQL must sit behind an Envoy sidecar, keep the given ports open, and expose Envoy's metrics."
  }

  assert {
    condition = (
      jsondecode(consul_config_entry.intentions[0].config_json).Sources == [{ Name = "odoo", Action = "allow", Precedence = 9, Type = "consul" }, { Name = "sauron-ui", Action = "allow", Precedence = 9, Type = "consul" }]
      && jsondecode(consul_config_entry.defaults[0].config_json).Protocol == "tcp"
    )
    error_message = "Only the allowed services may connect, and the protocol is tcp."
  }
}

run "out_of_the_mesh_by_default" {
  command = apply

  assert {
    condition     = !strcontains(nomad_job.postgres.jobspec, "connect {") && length(consul_config_entry.intentions) == 0
    error_message = "Without mesh.enabled there is no sidecar and no intentions."
  }
}

run "in_the_mesh_the_port_is_static_only_while_kept_open" {
  command = apply

  variables {
    mesh = { enabled = true, allow = ["x"] }
  }

  assert {
    condition     = !strcontains(nomad_job.postgres.jobspec, "static       = 5432")
    error_message = "Nomad lets a static port bypass the sidecar: in the mesh the postgres port must be dynamic unless kept open."
  }
}
