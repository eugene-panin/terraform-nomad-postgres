variable "vault_kv_path" {
  description = "Path of the Vault KV v2 engine the admin credential is kept in; the platform gives it."
  type        = string
}

variable "namespace" {
  description = "Nomad namespace the job runs in."
  type        = string
  default     = "default"
}

variable "job_name" {
  description = "Name of the Nomad job and the Consul service other apps reach it by."
  type        = string
  default     = "postgres"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.job_name))
    error_message = "job_name must be lowercase letters, digits and -, starting with a letter."
  }
}

variable "datacenters" {
  description = "Nomad datacenters the job may run in."
  type        = list(string)
  default     = ["*"]
}

variable "image" {
  description = "PostgreSQL container image, pinned by a fixed tag or a digest."
  type        = string
  default     = "postgres:16.10"
}

variable "admin_user" {
  description = "Name of the PostgreSQL superuser. Its password is generated and kept in Vault; consumer apps use it to create their own role and database."
  type        = string
  default     = "postgres"
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.admin_user))
    error_message = "admin_user must be lowercase letters, digits and _, starting with a letter."
  }
}

variable "port" {
  description = "Port PostgreSQL listens on, on the internal host network. Consumers connect to the server's internal address on this port."
  type        = number
  default     = 5432
}

variable "internal_host_network" {
  description = "Nomad host network PostgreSQL binds to. Never the public network: a shared database is reachable only inside the platform."
  type        = string
  default     = "default"
}

variable "resources" {
  description = "CPU (MHz) and memory (MB) for the PostgreSQL task: memory is what it reserves (sized to its use), memory_max how far it may grow (Nomad memory oversubscription)."
  type = object({
    cpu        = optional(number, 500)
    memory     = optional(number, 768)
    memory_max = optional(number, 2048)
  })
  default = {}
  validation {
    condition     = var.resources.memory_max >= var.resources.memory
    error_message = "resources.memory_max must be at least resources.memory."
  }
}

variable "mesh" {
  description = <<-EOT
    The Consul service mesh. enabled puts PostgreSQL behind an Envoy sidecar (transparent
    proxy): mesh services reach it as <job_name>.virtual.consul over mTLS, and only those in
    allow may (Consul intentions; any other is denied). keep_open_ports stay reachable
    outside the mesh — for clients not in it yet, during a move into it. protocol is what
    Consul's L7 features see: tcp for PostgreSQL.
  EOT
  type = object({
    enabled         = optional(bool, false)
    allow           = optional(list(string), [])
    keep_open_ports = optional(list(number), [])
    protocol        = optional(string, "tcp")
  })
  default = {}
  validation {
    condition     = contains(["tcp", "http", "http2", "grpc"], var.mesh.protocol)
    error_message = "mesh.protocol must be tcp, http, http2 or grpc."
  }
}
