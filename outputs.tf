output "urls" {
  description = "Each host's UI address as it listens, by host name. On loopback, reach it through a TLS proxy or an SSH tunnel."
  value       = { for name, h in var.hosts : name => "http://${var.listen}" }
}

output "admin_password_hint" {
  description = "Where the first admin password is. The UI prints it to its log once, on its first start."
  value       = "journalctl -u conn3x-ui | grep -i password"
}
