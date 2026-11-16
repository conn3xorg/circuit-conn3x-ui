variable "port" {
  type    = number
  default = 2222
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
}

output "urls" {
  value = module.conn3x_ui.urls
}
