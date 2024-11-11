output "db-pip" {
  description = "the ip address of the db"
  value       = azurerm_public_ip.public_ip_db.ip_address
}

output "web-pip" {
  description = "the ip address of the web"
  value       = azurerm_public_ip.public_ip_web.ip_address
}


output "web-address" {
  description = "the address of the web"
  value       = "http://${azurerm_public_ip.public_ip_web.ip_address}:3000"
}

output "ssh-connection-web" {
  description = ""
  value       = "ssh adminuser@${azurerm_public_ip.public_ip_web.ip_address}"
}

output "ssh-connection-fb" {
  description = ""
  value       = "ssh adminuser@${azurerm_public_ip.public_ip_db.ip_address}"
}

