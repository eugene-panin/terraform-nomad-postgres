locals {
  secret_name    = "${var.namespace}/${var.job_name}/admin"
  volume_name    = "${var.job_name}-data"
  admin_secret   = { username = var.admin_user, password = random_password.admin.result }
  secret_version = parseint(substr(sha256(jsonencode(local.admin_secret)), 0, 8), 16)
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "vault_kv_secret_v2" "admin" {
  mount                = var.vault_kv_path
  name                 = local.secret_name
  data_json_wo         = jsonencode(local.admin_secret)
  data_json_wo_version = local.secret_version
}

resource "nomad_dynamic_host_volume" "data" {
  name      = local.volume_name
  namespace = var.namespace
  plugin_id = "mkdir"

  parameters = {
    mode = "0700"
    uid  = "999"
    gid  = "999"
  }

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
}

resource "nomad_job" "postgres" {
  jobspec = templatefile("${path.module}/templates/postgres.nomad.hcl.tftpl", {
    job_name         = var.job_name
    namespace        = var.namespace
    datacenters      = var.datacenters
    volume_name      = nomad_dynamic_host_volume.data.name
    secret_path      = "${var.vault_kv_path}/data/${local.secret_name}"
    secret_version   = local.secret_version
    internal_network = var.internal_host_network
    image            = var.image
    admin_user       = var.admin_user
    port             = var.port
    resources        = var.resources
    mesh             = var.mesh
  })

  purge_on_destroy = true

  depends_on = [vault_kv_secret_v2.admin]
}

# In the mesh: what Consul's L7 features see, and who may connect (intentions;
# the platform's ACLs deny any other).
resource "consul_config_entry" "defaults" {
  count = var.mesh.enabled ? 1 : 0

  kind = "service-defaults"
  name = var.job_name
  config_json = jsonencode({
    Protocol = var.mesh.protocol
  })
}

resource "consul_config_entry" "intentions" {
  count = var.mesh.enabled ? 1 : 0

  kind = "service-intentions"
  name = var.job_name
  config_json = jsonencode({
    Sources = [for s in var.mesh.allow : { Name = s, Action = "allow" }]
  })
}
