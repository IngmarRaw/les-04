terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

locals {
  esxi_config = yamldecode(file("${path.module}/../ansible/group_vars/esxi.yml"))

  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

provider "esxi" {
  esxi_hostname = local.esxi_config.esxi_hostname
  esxi_hostport = local.esxi_config.esxi_hostport
  esxi_hostssl  = local.esxi_config.esxi_hostssl
  esxi_username = local.esxi_config.esxi_username
  esxi_password = var.esxi_password
}

resource "esxi_guest" "webserver" {
  guest_name = var.webserver_name
  disk_store = var.disk_store

  memsize  = var.vm_memory
  numvcpus = var.vm_vcpu
  power    = "on"

  ovf_source = var.ovf_source

  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "userdata" = base64gzip(templatefile("${path.module}/cloudinit.tftpl", {
      username       = var.vm_username
      ssh_public_key = local.ssh_public_key
    }))
    "userdata.encoding" = "gzip+base64"

    "metadata" = base64gzip(jsonencode({
      "local-hostname" = var.webserver_name
      "instance-id"    = var.webserver_name
    }))
    "metadata.encoding" = "gzip+base64"
  }
}

resource "esxi_guest" "databaseserver" {
  guest_name = var.databaseserver_name
  disk_store = var.disk_store

  memsize  = var.vm_memory
  numvcpus = var.vm_vcpu
  power    = "on"

  ovf_source = var.ovf_source

  network_interfaces {
    virtual_network = var.virtual_network
  }

  guestinfo = {
    "userdata" = base64gzip(templatefile("${path.module}/cloudinit.tftpl", {
      username       = var.vm_username
      ssh_public_key = local.ssh_public_key
    }))
    "userdata.encoding" = "gzip+base64"

    "metadata" = base64gzip(jsonencode({
      "local-hostname" = var.databaseserver_name
      "instance-id"    = var.databaseserver_name
    }))
    "metadata.encoding" = "gzip+base64"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = <<-EOT
[webservers]
${esxi_guest.webserver.guest_name} ansible_host=${esxi_guest.webserver.ip_address}

[databaseservers]
${esxi_guest.databaseserver.guest_name} ansible_host=${esxi_guest.databaseserver.ip_address}

[esxi:children]
webservers
databaseservers

[all:vars]
ansible_user=${var.vm_username}
ansible_ssh_private_key_file=${var.ssh_private_key_path}
ansible_python_interpreter=/usr/bin/python3
EOT
}