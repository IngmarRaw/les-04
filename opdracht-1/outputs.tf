output "webserver_name" {
  description = "Naam van de webserver VM"
  value       = esxi_guest.webserver.guest_name
}

output "webserver_ip" {
  description = "IP-adres van de webserver VM"
  value       = esxi_guest.webserver.ip_address
}

output "databaseserver_name" {
  description = "Naam van de database VM"
  value       = esxi_guest.databaseserver.guest_name
}

output "databaseserver_ip" {
  description = "IP-adres van de database VM"
  value       = esxi_guest.databaseserver.ip_address
}

output "ansible_inventory_path" {
  description = "Pad naar de gegenereerde Ansible inventory"
  value       = local_file.ansible_inventory.filename
}