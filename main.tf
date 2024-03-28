resource "aws_security_group" "jenkins_mutual_sg" {
  name   = "jenkins_mutual_sec_group"
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = {
    Name = "jenkins_mutual_secgroup"
  }
}

resource "aws_security_group" "jenkins_server_sg" {
  name   = "jenkins_server_sec_group"
   vpc_id = aws_vpc.jenkins_vpc.id
  # Allow outgoing traffic
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  # Allow incoming traffic 
  ingress = [
    {
      # Allow ssh access on port 22 from all sources
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "SSH Access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "HTTP Access"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Jenkins Access"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = "Jenkins to Docker Access"
      from_port        = 32768 
      to_port          = 60999
      protocol         = "tcp"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
  tags = {
    Name                               = "jenkins_server_sec_group"
    terraform_group                    = "jenkins_server"
  }
}

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.24.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name            = "jenkins_vpc"
    terraform_group = "jenkins_server"
  }
}

resource "aws_subnet" "jenkins_public_subnet" {
  vpc_id     = aws_vpc.jenkins_vpc.id
  cidr_block = "10.24.1.0/24"

  tags = {
    Name                               = "jenkins_public_subnet"
    terraform_group                    = "jenkins_server"
  }
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name            = "Jenkins Internet Gateway"
    terraform_group = "jenkins_server"
  }
}

resource "aws_route_table" "jenkins_public_rt" {
  # The VPC ID.
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    # The CIDR block of the route.
    cidr_block = "0.0.0.0/0"

    # Identifier of a VPC internet gateway or a virtual private gateway.
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  # A map of tags to assign to the resource.
  tags = {
    Name            = "jenkins_public_rt"
    terraform_group = "jenkins_server"
  }
}

resource "aws_route_table_association" "public1" {
  # The subnet ID to create an association.
  subnet_id = aws_subnet.jenkins_public_subnet.id

  # The ID of the routing table to associate with.
  route_table_id = aws_route_table.jenkins_public_rt.id
}

resource "tls_private_key" "jenkins_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_kp" {
  key_name   = "jenkins_key" # Create a "jenkins_key" on AWS.
  public_key = tls_private_key.jenkins_pk.public_key_openssh

  provisioner "local-exec" { # Copy a "jenkins_key.pem" to local computer.
    command = "echo '${tls_private_key.jenkins_pk.private_key_pem}' > ${path.cwd}/.ssh/jenkins_key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/.ssh/jenkins_key.pem"
  }

  tags = {
    terraform_group = "jenkins_server"
  }
}


resource "aws_instance" "jenkins_server_instance" {
  ami                  = var.instance_ami
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.jenkins_public_subnet.id
  associate_public_ip_address = "true"
  tags = {
    Name                               = "jenkins_server_instance"
    terraform_group                    = "jenkins_server"
  }

  key_name               = "jenkins_key"
  vpc_security_group_ids = [aws_security_group.jenkins_mutual_sg.id, aws_security_group.jenkins_server_sg.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.instance_user
    private_key = file("${path.cwd}/.ssh/jenkins_key.pem")
    timeout     = "4m"
  }

  root_block_device {
    delete_on_termination = true
    encrypted = false
    volume_size = 30
    volume_type = "gp3"
    throughput = 125
    iops = 3000
  }
}

# resource "aws_ebs_volume" "example" {
#   availability_zone = aws_instance.jenkins_server_instance.availability_zone
#   size              = 40
#   tags = {
#     Name = "ebs_volume"
#   }
# }

# resource "aws_volume_attachment" "example" {
#   device_name = "/dev/sdh"
#   volume_id   = aws_ebs_volume.example.id
#   instance_id = aws_instance.example.id
# }

# Ansible Section 

resource "ansible_host" "jenkins_server" {
  name   = aws_instance.jenkins_server_instance.public_ip
  groups = ["jenkins_server"]

  variables = {
    ansible_user                 = var.instance_user
    ansible_ssh_private_key_file = "./.ssh/jenkins_key.pem"
    ansible_python_interpreter   = "/usr/bin/python3"
    host_name                    = aws_instance.jenkins_server_instance.tags["Name"]
    private_ip                   = aws_instance.jenkins_server_instance.private_ip
  }
}