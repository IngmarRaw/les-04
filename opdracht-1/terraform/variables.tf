variable "esxi_password" {
  type      = string
  sensitive = true
}

variable "disk_store" {
  type    = string
  default = "datastore1"
}

variable "virtual_network" {
  type    = string
  default = "VM Network"
}

variable "ovf_source" {
  type    = string
  default = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "vm_username" {
  type    = string
  default = "iacuser"
}

variable "webserver_name" {
  type    = string
  default = "les04-webserver"
}

variable "databaseserver_name" {
  type    = string
  default = "les04-database"
}

variable "vm_vcpu" {
  type    = number
  default = 1
}

variable "vm_memory" {
  type    = number
  default = 2048
}