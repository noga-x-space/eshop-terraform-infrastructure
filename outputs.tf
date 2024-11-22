
output "web-address" {
  description = "the address of the web"
  value       = "http://${azurerm_public_ip.public_ip_web.ip_address}:3000"
}

