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
