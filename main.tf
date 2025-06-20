provider "aws" {
  region = "us-east-1" 
}

# ------------ VPC ------------
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "jenkins-vpc" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "jenkins-public-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = { Name = "jenkins-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "jenkins-rt" }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

# ------------ Security Group ------------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-security-group" }
}

# ------------ IAM Role for EC2 ------------
resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ------------ EC2 Instance ------------
resource "aws_instance" "jenkins_ec2" {
  ami                         = "ami-0fc5d935ebf8bc3bc" # Amazon Linux 2023, us-east-1
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  key_name                    = "jenkins-test" 
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker
              service docker start
              usermod -a -G docker ec2-user
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo yum install java-17-amazon-corretto -y
              sudo yum upgrade
              yum install jenkins -y
              systemctl start jenkins
              systemctl enable jenkins
            EOF

  tags = {
    Name = "jenkins-server"
  }
}

# ------------ Outputs ------------
output "jenkins_url" {
  value = "http://${aws_instance.jenkins_ec2.public_ip}:8080"
}

output "ec2_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip