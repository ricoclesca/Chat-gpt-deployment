resource "aws_security_group" "Jenkins-sg" {
  name        = "Jenkins-Security Group"
  description = "Open 22,443,80,8080,9000,9100,9090,3000"

  # Define a single ingress rule to allow traffic on all specified ports
  ingress = [
    for port in [22, 80, 443, 8080, 9000, 9100, 9090, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "Jenkins-sg"
    Project = "gpt"
  }
}


resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec" #change your ami value according to your aws instance
  instance_type          = "t2.large"
  key_name               = "linux_instance"
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  user_data              = templatefile("./script.sh", {})

  tags = {
    Name    = "gpt clone"
    Project = "gpt"
  }
  root_block_device {
    volume_size = 30
  }
}
resource "aws_instance" "web2" {
  ami                    = "ami-0c7217cdde317cfec" #change your ami value according to your aws instance 
  instance_type          = "t2.medium"
  key_name               = "linux_instance"
  vpc_security_group_ids = [aws_security_group.Jenkins-sg.id]
  tags = {
    Name    = "Monitering via grafana"
    Project = "gpt"
  }
  root_block_device {
    volume_size = 30
  }
}


# S3 bucket for Terraform backend
resource "aws_s3_bucket" "terraform_backend" {
  bucket = "gpt-deployment-rico"

  tags = {
    Name        = "Terraform Backend Bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "jenkins_execution" {
  name = "jenkins-terraform-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "JenkinsTerraformExecutionRole"
  }
}

resource "aws_iam_policy" "jenkins_execution_policy" {
  name        = "jenkins-permissions-policy"
  description = "Permissions for Jenkins to deploy EKS and manage related AWS resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:*",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:ListPolicyTags",
          "iam:ListRoleTags",
          "iam:ListPolicies",
          "iam:ListInstanceProfilesRoles",
          "iam:ListInstanceProfiles",
          "iam:ListAttachedGroupPolicies",
          "iam:ListGroupPolicies",
          "ec2:*",
          "s3:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_attach_policy" {
  role       = aws_iam_role.jenkins_execution.name
  policy_arn = aws_iam_policy.jenkins_execution_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_execution.name
}
