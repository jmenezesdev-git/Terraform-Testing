resource "aws_vpc" "tutorial_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "tutorial_public_subnet" {
  vpc_id                  = aws_vpc.tutorial_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ca-central-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "tutorial_internet_gateway" {
  vpc_id = aws_vpc.tutorial_vpc.id

  tags = {
    Name = "dev-igw"
  }
}


resource "aws_route_table" "tutorial_rt" {
  vpc_id = aws_vpc.tutorial_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}


resource "aws_route" "tutorial_default_route" {
  route_table_id         = aws_route_table.tutorial_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tutorial_internet_gateway.id
}

resource "aws_route_table_association" "tutorial_public_assoc" {
  subnet_id      = aws_subnet.tutorial_public_subnet.id
  route_table_id = aws_route_table.tutorial_rt.id
}

resource "aws_security_group" "tutorial_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.tutorial_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["70.48.14.26/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tutorial_auth"{
  key_name = "aws_tf_key"
  public_key = file("~/.ssh/aws_tf_key.pub")
}

resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.tutorial_server_ami.id
  key_name = aws_key_pair.tutorial_auth.id
  vpc_security_group_ids = [aws_security_group.tutorial_sg.id]
  subnet_id = aws_subnet.tutorial_public_subnet.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/aws_tf_key"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

}


# terraform plan
# terraform apply -auto-approve
# terraform show state aws_vpc.mtc_vpc
# terraform.io/language/state

# terraform destroy -auto-approve

#ssh -i ~/.ssh/aws_.... ubuntu@<thatIP>
#view command palette, Connect....