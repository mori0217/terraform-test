# key pair
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/tastylog-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

# ssm parameter store
# mysql_host
resource "aws_ssm_parameter" "mysql_host" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  type  = "String"
  value = aws_db_instance.mysql_standalone.address
}

# mysql_port
resource "aws_ssm_parameter" "mysql_port" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}
# mysql_database
resource "aws_ssm_parameter" "mysql_database" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
  type  = "String"
  value = aws_db_instance.mysql_standalone.db_name
}

# mysql_username
resource "aws_ssm_parameter" "mysql_username" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.username
}
# mysql_password
resource "aws_ssm_parameter" "mysql_password" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.password
}

# ec2
# resource "aws_instance" "app_server" {
#   ami                         = data.aws_ami.app_ami.id
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public_subnet_1a.id
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name
#   vpc_security_group_ids = [
#     aws_security_group.app_security_group.id,
#     aws_security_group.opmng_security_group.id
#   ]
#   key_name = aws_key_pair.keypair.key_name

#   tags = {
#     Name    = "${var.project}-${var.environment}-appserver"
#     Project = var.project
#     Env     = var.environment
#     Type    = "app"
#   }
# }

# launch template
resource "aws_launch_template" "app_launch_template" {
  update_default_version = true

  name = "${var.project}-${var.environment}-app-launch-template"

  image_id = data.aws_ami.app_ami.id

  key_name = aws_key_pair.keypair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-appserver"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }
  network_interfaces {

    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_security_group.id,
      aws_security_group.opmng_security_group.id
    ]
    delete_on_termination = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  user_data = filebase64("./src/initialize.sh")
}

# auto scaling group
resource "aws_autoscaling_group" "app_autoscaling_group" {
  name = "${var.project}-${var.environment}-app-autoscaling-group"

  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]

  target_group_arns = [
    aws_lb_target_group.alb_target_group.arn
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_launch_template.id
        version            = "$Latest"
      }
      override {
        instance_type = "t2.micro"
      }
    }
  }
}