"""An AWS Python Pulumi program"""

import pulumi
import pulumi_aws as aws
from pulumi_aws import s3, ec2

# # Create an AWS resource (S3 Bucket)
# bucket = s3.BucketV2('my-bucket')

# # Export the name of the bucket
# pulumi.export('bucket_name', bucket.id)

# Create a VPC
vpc = ec2.Vpc(
    'pulumi-vpc',
    cidr_block='10.0.0.0/16',
    enable_dns_support=True,
    enable_dns_hostnames=True,
    tags={
        'Name': 'pulumi-vpc'
    }
)

pulumi.export('vpc_id', vpc.id)
####################################
# Create Pulbic Subnet
public_subnet = ec2.Subnet(
    'jenkins-subnet',
    vpc_id=vpc.id,
    cidr_block='10.0.1.0/24',
    availability_zone='us-west-2a',
    map_public_ip_on_launch=True,
    tags={
        'Name': 'jenkins-subnet'
    }
)
####################################
# Create Internet Gateway
internet_gateway = ec2.InternetGateway(
    'jenkins-igateway',
    vpc_id=vpc.id,
    tags={
        'Name': 'jenkins-igateway'
    }
)
####################################
# Route Table for Internet Gateway
route_table = ec2.RouteTable(
    'jenkins-route-table',
    vpc_id=vpc.id,
    tags={
        'Name': 'jenkins-route-table'
    }
)
####################################
# Create Default Route for Internet Gateway
default_route = ec2.Route(
    'jenkins-default-route',
    route_table_id=route_table.id,
    destination_cidr_block='0.0.0.0/0',
    gateway_id=internet_gateway.id
)
####################################
# Associate Route Table with Public Subnet
ec2.RouteTableAssociation(
    'jenkins-route-table-association',
    subnet_id=public_subnet.id,
    route_table_id=route_table.id
)
####################################
# Create Security Group for Jenkins
security_group = ec2.SecurityGroup(
    'jenkins-security-group',
    vpc_id=vpc.id,
    description='Jenkins Security Group',
    ingress=[
        {
            'from_port': 0,
            'to_port': 0,
            'protocol': '-1',
            'cidr_blocks': ['0.0.0.0/0']
        },
        {
            'from_port': 22,
            'to_port': 22,
            'protocol': 'tcp',
            'cidr_blocks': ['10.0.1.0/24']  # Allow SSH from within the subnet
        }
    ],
    egress=[
        {
            'from_port': 0,
            'to_port': 0,
            'protocol': '-1',
            'cidr_blocks': ['0.0.0.0/0']
        }
    ],
    tags={
        'Name': 'jenkins-security-group'
    }
)
####################################
# Create Key Pair for Jenkins
key_pair = ec2.KeyPair(
    'jenkins-key-pair',
    key_name='jenkins-key-pair',
    public_key=open('/home/angel.cruz/.ssh/id_rsa.pub').read()
)
####################################
# Create Jenkins Instance
latest_ami = aws.ec2.get_ami(
    most_recent=True,  # Specifies that you want the most recent AMI if multiple match
    owners=["amazon"],  #  Specifies the owner of the AMI (e.g., "amazon" for official Amazon AMIs)
    filters=[{"name": "name", "values": ["al2023-ami-*-kernel-6.1-x86_64"]}], #  Filters the AMIs based on their name
)


jenkins_instance = ec2.Instance(
    'jenkins-instance',
    ami=latest_ami.id,
    instance_type='t2.micro',
    subnet_id=public_subnet.id,
    vpc_security_group_ids=[security_group.id],
    key_name=key_pair.key_name,
    user_data="""#!/bin/bash
sudo yum update -y
sudo yum install -y python3-pip
sudo pip3 install ansible

# Create ansible user with sudo privileges
sudo useradd -m -s /bin/bash ansible
echo "ansible:ansible" | sudo chpasswd

# Add ansible user to sudo group
sudo usermod -aG wheel ansible

# Configure sudoers to allow ansible user to run sudo without password
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible

# Set proper permissions on sudoers file
sudo chmod 440 /etc/sudoers.d/ansible
""",
    tags={
        'Name': 'jenkins-instance-1'
    }
)

jenkins_instance_2 = ec2.Instance(
    'jenkins-instance-2',
    ami=latest_ami.id,
    instance_type='t2.micro',
    subnet_id=public_subnet.id,
    vpc_security_group_ids=[security_group.id],
    key_name=key_pair.key_name,
    tags={
        'Name': 'jenkins-instance-2'
    }
)
####################################
# Export the Jenkins Instance ID
pulumi.export('jenkins_instance_id_1', jenkins_instance.id)
pulumi.export('jenkins_instance_id_2', jenkins_instance_2.id)
pulumi.export('jenkins_instance_1_public_ip', jenkins_instance.public_ip)
pulumi.export('jenkins_instance_2_public_ip', jenkins_instance_2.public_ip)