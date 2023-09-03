resource "aws_instance" "server" {
    ami = "ami-07d6bd9a28134d3b3"
    instance_type = var.instance_type
    tags = {
        Name = "nginx-server"
    }
    user_data = <<-EOF
        #!/bin/bash
        amazon-linux-extras install -y nginx
        sudo systemctl start nginx
        sudo systemctl enable nginx
    EOF
    }