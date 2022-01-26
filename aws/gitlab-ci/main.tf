data aws_region current {}

locals {
  names = [for i in range(var.instance_count) : "${var.project_prefix}-${var.name}-${i + 1}"]
}

module shared_ci {
  source                     = "../../shared/ci"
  names                      = local.names
  username                   = var.username
  runner_tags                = var.runner_tags
  gitlab_token               = data.aws_kms_secrets.ci.plaintext["gitlab_token"]
  gitlab_runner_concurrency  = var.gitlab_runner_concurrency
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_docker_image = var.gitlab_runner_docker_image
  gitlab_runner_locked       = var.gitlab_runner_locked
  docker_prune_cron_schedule = var.docker_prune_cron_schedule
}

data aws_kms_secrets ci {
  secret {
    name    = "gitlab_token"
    payload = var.encrypted_gitlab_token

    context = {
      usage = "gitlab-token"
    }
  }
}

resource tls_private_key ci_ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource aws_key_pair ci_ssh {
  key_name   = "ci-ssh"
  public_key = tls_private_key.ci_ssh.public_key_openssh
  tags       = var.tags
}

data aws_ami image {
  most_recent = true

  filter {
    name   = "name"
    values = var.image_names
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = var.image_owners
}

resource aws_instance ci {
  count         = var.instance_count
  ami           = data.aws_ami.image.id
  instance_type = var.instance_type
  tags          = merge(var.tags, { "Name" : local.names[count.index] })
  key_name      = aws_key_pair.ci_ssh.key_name

  network_interface {
    network_interface_id = aws_network_interface.ci[count.index].id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }

  provisioner remote-exec {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.ci_ssh.private_key_pem
      host        = aws_eip.ci[count.index].public_ip
    }

    inline = module.shared_ci.provisioner_commands[count.index]
  }
}

resource aws_vpc ci {
  cidr_block = "10.0.0.0/16"
  tags       = var.tags
}

resource aws_internet_gateway ci {
  vpc_id = aws_vpc.ci.id
  tags   = var.tags
}

resource aws_subnet ci {
  count             = var.instance_count > length(var.availability_zones) ? length(var.availability_zones) : var.instance_count
  vpc_id            = aws_vpc.ci.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = join("", [data.aws_region.current.name, var.availability_zones[count.index % length(var.availability_zones)]])
  tags              = var.tags
}

resource aws_security_group ci {
  description = "CI server security group"
  vpc_id      = aws_vpc.ci.id
  tags        = var.tags

  ingress {
    description = "Allow ssh access to the ci server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_ranges
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource aws_network_interface ci {
  count           = var.instance_count
  subnet_id       = aws_subnet.ci[count.index % length(aws_subnet.ci)].id
  tags            = var.tags
  security_groups = [aws_security_group.ci.id]
}

resource aws_eip ci {
  count             = var.instance_count
  vpc               = true
  network_interface = aws_network_interface.ci[count.index].id
  tags              = var.tags
  depends_on        = [aws_internet_gateway.ci]
}

resource aws_route_table main {
  vpc_id = aws_vpc.ci.id
  tags   = var.tags
}

resource aws_route internet {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ci.id
}

resource aws_main_route_table_association main {
  vpc_id         = aws_vpc.ci.id
  route_table_id = aws_route_table.main.id
}
