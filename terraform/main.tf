####################################
# Create a VPC
####################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
  Name = "main-vpc" }

}

####################################
# Create Public Subnet
####################################
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  map_public_ip_on_launch = true
  tags = {
    Name = "main-public-subnet"
  }
}


####################################
# Create Internet Gateway
####################################
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

####################################
# Route Table for Internet Gateway
####################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-public-route-table"
  }
}

####################################
# Create Default Route for Internet Gateway
####################################
resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main-igw.id
}

####################################
# Associate Route Table with Public Subnet
####################################
resource "aws_route_table_association" "main-public-rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

####################################
# Create Security Group for Jenkins
####################################

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "jenkins-sg"
  }

}
####################################
# Create Key Pair for Jenkins
####################################

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file(var.local_public_key_path) # Path to the local public key)
}

# Loop through available AWS UbuntU AMIs and find latest 
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID for Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}


####################################
# Create Jenkins Instance
####################################

resource "aws_instance" "jenkins_instance" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id] 
  
  tags = {
    Name = "Jenkins-Instance"
  }

  # user_data = <<-EOF
  #             #!/bin/bash
  #             sudo apt-get update
  #             sudo apt-get install -y openjdk-11-jdk
  #             wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
  #             sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  #             sudo apt-get update
  #             sudo apt-get install -y jenkins
  #             sudo systemctl start jenkins
  #             EOF

}

# output the Jenkins Instance ID and Public IP
output "jenkins_instance_id" {
  value = aws_instance.jenkins_instance.id
}
output "jenkins_instance_public_ip" {
  value = aws_instance.jenkins_instance.public_ip
} 

####################################
# Create 2nd Instance
####################################

####################################
# Output the Jenkins Instance ID
