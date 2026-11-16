variable "port" {
  type    = number
  default = 2222
}

# CI sets these to install an older conn3x-ui first, then upgrades to the
# circuit's own pin by applying again without them.
variable "conn3x_ui_version" {
  type    = string
  default = null
}

variable "conn3x_ui_checksums" {
  type    = map(string)
  default = null
}

module "conn3x_ui" {
  source = "../.."

  hosts                = { box = "127.0.0.1" }
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"
  # Inside the container, so up.sh's port forward reaches it. The forward
  # itself is on 127.0.0.1 only.
  listen = "0.0.0.0:8080"

  conn3x_ui_version   = var.conn3x_ui_version
  conn3x_ui_checksums = var.conn3x_ui_checksums
}

output "urls" {
  value = module.conn3x_ui.urls
}
