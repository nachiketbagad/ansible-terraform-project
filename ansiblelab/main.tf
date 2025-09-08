provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# ⿡ Generate Ansible Inventory File
# -----------------------------
resource "local_file" "ansible_inventory" {
  content = templatefile(
    "./templates/hosts.tpl",
    {
      keyfile     = var.pemfile
      demoservers = aws_instance.ansible_nodes.*.public_ip
    }
  )

  filename    = "./ansible/hosts.cfg"
  depends_on  = [aws_instance.ansible_nodes] # ensures nodes exist before generating IPs
}

# -----------------------------
# ⿢ Create EC2 Ansible Controller
# -----------------------------
resource "aws_instance" "ansible_controller" {
  ami                         = var.amiid
  instance_type               = var.type
  key_name                    = var.pemfile
  associate_public_ip_address = true
  depends_on                  = [local_file.ansible_inventory]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y ansible
  EOF

  tags = {
    Name = "ANSIBLE CONTROLLER"
  }

  # Copy hosts.cfg to controller
  provisioner "file" {
    source      = "./ansible/hosts.cfg"
    destination = "/home/ubuntu/hosts.cfg"
  }

  # Copy PEM key to controller
  provisioner "file" {
    source      = "./${var.pemfile}.pem"
    destination = "/home/ubuntu/${var.pemfile}.pem"
  }

  # Set correct permissions for key
  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/${var.pemfile}.pem"
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${var.pemfile}.pem")
  }
}

# -----------------------------
# ⿣ Create EC2 Ansible Worker Nodes
# -----------------------------
resource "aws_instance" "ansible_nodes" {
  count                       = var.servercount
  ami                         = var.amiid
  instance_type               = var.type
  key_name                    = var.pemfile
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y python3
  EOF

  tags = {
    Name = "ANSIBLE TARGET NODE"
  }
}
