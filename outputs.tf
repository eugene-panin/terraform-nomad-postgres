output "job_id" {
  description = "ID of the PostgreSQL job in Nomad."
  value       = nomad_job.postgres.id
}

output "service_name" {
  description = "Consul service name other apps reach PostgreSQL by."
  value       = var.job_name
}

output "port" {
  description = "Port PostgreSQL listens on, on the internal host network."
  value       = var.port
}

output "admin_user" {
  description = "Name of the PostgreSQL superuser."
  value       = var.admin_user
}

output "admin_secret" {
  description = "Vault KV name (under the mount) holding the superuser {username, password}. A consumer app reads it to create its own role and database."
  value       = local.secret_name
}

output "data_volume" {
  description = "Name of the dynamic host volume holding the PostgreSQL data."
  value       = nomad_dynamic_host_volume.data.name
}

output "admin_password" {
  description = "Generated password of the PostgreSQL superuser."
  value       = random_password.admin.result
  sensitive   = true
}
