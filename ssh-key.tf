#// variables.tf
variable "pvt_key" {}
variable "pub_key" {}

#// main.tf
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  sensitive_content         = tls_private_key.ssh.private_key_pem
  filename        = "ssh-key.pem"
  file_permission = "0600"
  provisioner "local-exec" {
    command = "chmod 600 ssh-key.pem"
  }
}

resource "local_file" "public_key" {
  sensitive_content         = tls_private_key.ssh.public_key_openssh
  filename        = "ssh-key-public.pem"
  file_permission = "0600"
}

locals {
  servers = toset(["web1","web2"])
}
