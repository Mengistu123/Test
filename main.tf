provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

# Launch an EC2 instance for the Kubernetes master node
resource "aws_instance" "k8s_master" {
  ami           = "ami-0dba2cb6798deb6d8" # Specify the AMI ID for your Kubernetes master node
  instance_type = "t2.micro"         # Adjust the instance type as needed
  security_groups = [aws_security_group.managers_security_group.name]
  iam_instance_profile = module.roles.iam_instance_profile_master
  tags = {
    Name = "master_node"
  }
}
resource "aws_instance" "k8s_workers" {
  count         = 2
  ami           = "ami-0dba2cb6798deb6d8" # Specify the AMI ID for your Kubernetes worker nodes
  instance_type = "t2.micro"         # Adjust the instance type as needed
  root_block_device {
    volume_size = "20"
  }
  security_groups = [aws_security_group.workers_security_group.name]
  iam_instance_profile = module.roles.iam_instance_profile_worker
  tags = {
    Name = "worker_nodes"
  }
}
# Security Group for Kube Masters
resource "aws_security_group" "managers_security_group" {
  name = "managers_security_group"
  description = "Enable SSH and Kubernetes API access for Kube Masters"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #Kubernetes API server|All|
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress { #`etcd` server client API|kube-apiserver, etcd|
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #Kubelet API|Self, Control plane|
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #kube-controller-manager|Self|
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #kube-scheduler|Self|
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #Cluster-Wide Network Comm. - Flannel VXLAN|Self|
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "allow_inbound_from_worker" {
  type        = "ingress"
  from_port   = 50
  to_port     = 50
  protocol    = "tcp"
  security_group_id = aws_security_group.workers_security_group.id  # Referencing worker sg by ID
  source_security_group_id = aws_security_group.managers_security_group.id  # Referencing master sg by ID
}

# Security Group for Kube Workers
resource "aws_security_group" "workers_security_group" {
  name = "workers_security_group"
  description = "Enable SSH and Kubernetes API access for Kube Workers"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress { #Kubelet API|Self, Control plane|
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #Cluster-Wide Network Comm. - Flannel VXLAN|Self|
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

#Outputs

module "roles" {
  source = "./modules/IAM/" # This should point to the directory containing your roles.tf file
}

output "KubeMasterPublicDNSName" {
  description = "Kube Master  Public DNS Name"
  value = aws_instance.k8s_master.public_dns
}

output "KubeMasterPrivateDNSName" {
  description = "Kube Master  Private DNS Name"
  value = aws_instance.k8s_master.private_dns
}

output "FirstKubeWorkerPublicDNSName" {
    description = "Kube Worker 1st Public DNS Name"
    value = aws_instance.k8s_workers[0].public_dns
}

output "FirstKubeWorkerPrivateDNSName" {
   description = "Kube Worker 1st Private DNS Name"
   value = aws_instance.k8s_workers[0].private_dns
}

output "SecondKubeWorkerPublicDNSName" {
   description = "Kube Worker 2nd Public DNS Name"
   value = aws_instance.k8s_workers[1].public_dns
}

output "SecondKubeWorkerPrivateDNSName" {
    description = "Kube Worker 2nd Private DNS Name"
    value = aws_instance.k8s_workers[1].private_dns
}




