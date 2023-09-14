# Policies


resource "aws_iam_policy" "master_node_policy" {
  name        = "k8s-master-policy"
  description = "IAM policy for Kubernetes master nodes"

  policy = file("./modules/IAM/policy_for_master.json")
}


resource "aws_iam_policy" "worker_node_policy" {
  name        = "k8s-worker-policy"
  description = "IAM policy for Kubernetes worker nodes"

  policy = file("./modules/IAM/policy_for_worker.json")
}


#Roles

resource "aws_iam_role" "master_node_role" {
  name = "k8s-master-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "worker_node_role" {
  name = "k8s-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attachment

resource "aws_iam_role_policy_attachment" "attach_master_policy" {
  policy_arn = aws_iam_policy.master_node_policy.arn
  role       = aws_iam_role.master_node_role.name
}

resource "aws_iam_role_policy_attachment" "attach_worker_policy" {
  policy_arn = aws_iam_policy.worker_node_policy.arn
  role       = aws_iam_role.worker_node_role.name
}

#Profiles

resource "aws_iam_instance_profile" "master_profile" {
  name = "master_profile"
  role = aws_iam_role.master_node_role.name
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "worker_profile"
  role = aws_iam_role.worker_node_role.name
}

#Outputs

output "iam_instance_profile_master" {
  description = "Master of the IAM instance profile"
  value       = aws_iam_instance_profile.master_profile.name
}

output "iam_instance_profile_worker" {
  description = "Worker of the IAM instance profile"
  value       = aws_iam_instance_profile.worker_profile.name
}