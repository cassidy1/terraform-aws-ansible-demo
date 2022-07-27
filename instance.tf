resource "aws_instance" "server" {
  for_each                    = toset(["web1", "web2", "web3"])
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]

  tags = {
    Name = "cassidy-${each.key}-instance"
  }

  provisioner "remote-exec" {
    #inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]
    inline = ["hostname", "echo Done!"]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' apache-install.yml"
  }
}

locals {
  # get json
  instances = [for instance in aws_instance.server : instance.public_ip]
}

#// outputs
output "instance_ip_addresses" {
  value = {
    for instance in aws_instance.server :
    instance.tags.Name => instance.public_ip
  }
  depends_on = [aws_instance.server]
}

output "instances" {
  value      = local.instances
  depends_on = [aws_instance.server]
}

#// Create inventory file for Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl", {
    web_servers = tomap({
      for instance in aws_instance.server :
      instance.tags.Name => instance.public_ip
    }) #local.servers[*]
    ssh_keyfile = local_file.private_key.filename
  })
  #filename = format("%s/%s", abspath(path.root), "${path.root}/inventory.yaml")
  filename   = "${path.root}/inventory.yaml"
  depends_on = [aws_instance.server]
}
