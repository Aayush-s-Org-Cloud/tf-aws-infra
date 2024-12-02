# S3 Full Access Policy
resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "S3_FullAccess_Policy"
  description = "Policy for full S3 access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket",
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl"
        ],
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

# Route53 Access Policy
resource "aws_iam_policy" "route53_access_policy" {
  name        = "Route53_FullAccess_Policy"
  description = "Policy for managing Route 53 records"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:UpdateHostedZoneComment",
          "route53:GetChange",
          "route53:GetCheckerIpRanges",
          "route53:ListHostedZonesByName",
          "route53:ListTagsForResource",
          "route53:ChangeTagsForResource",
          "route53:ListHealthChecks",
          "route53:GetHealthCheck",
          "route53:GetHostedZoneLimit",
          "route53:ListQueryLoggingConfigs",
          "route53domains:CheckDomainAvailability",
          "route53domains:RegisterDomain",
          "route53domains:DeleteDomain",
          "route53domains:GetDomainDetail",
          "route53domains:ListDomains",
          "route53domains:ListTagsForDomain",
          "route53domains:UpdateDomainContact",
          "route53domains:ViewBilling"
        ],
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Logging Policy
resource "aws_iam_policy" "cloudwatch_logging_policy" {
  name        = "CloudWatch_Logging_Policy"
  description = "Policy for CloudWatch logging and metrics"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "ssm:GetParameter",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      }
    ]
  })
}


# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "EC2RoleForRoute53_S3_CloudWatch"

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
    Name = "EC2RoleForRoute53_S3_CloudWatch"
  }
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfileForRoute53_S3_CloudWatch"
  role = aws_iam_role.ec2_role.name
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "lambda-exec-role"
  }
}
resource "aws_iam_policy" "lambda_ssm_access_policy" {
  name        = "Lambda_SSM_Access_Policy"
  description = "Policy to allow Lambda to access SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/sendgrid/api_key"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_ssm_access_policy.arn
}

resource "aws_iam_policy" "ec2_sns_publish_policy" {
  name        = "EC2_SNS_Publish_Policy"
  description = "Policy to allow EC2 instances to publish to the user-signup-topic SNS topic"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "arn:aws:sns:us-east-1:084828563934:user-signup-topic"
      }
    ]
  })
}
# Attach SNS Publish Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "ec2_sns_publish_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_sns_publish_policy.arn
}
# Attach Basic Lambda Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




# Attach S3 Full Access Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

# Attach Route53 Access Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "route53_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.route53_access_policy.arn
}

# Attach CloudWatch Logging Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_logging_policy.arn
}


# Policy for EC2 to access Database Password Secret
resource "aws_iam_policy" "ec2_secret_access_policy" {
  name        = "EC2_SecretsManager_Access_Policy"
  description = "Policy to allow EC2 instances to access Database Password secret"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.db_password_secret.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = aws_kms_key.secret_db_password_key.arn
      }
    ]
  })
}

# Policy for Lambda to access Email Credentials Secret
resource "aws_iam_policy" "lambda_secret_access_policy" {
  name        = "Lambda_SecretsManager_Access_Policy"
  description = "Policy to allow Lambda functions to access Email Credentials secret"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.email_credentials_secret.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = aws_kms_key.secret_email_credentials_key.arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ec2_secret_access_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_secret_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secret_access_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_secret_access_policy.arn
}



# Add KMS permissions to EC2 Role
resource "aws_iam_policy" "ec2_kms_access_policy" {
  name        = "EC2_KMS_Access_Policy"
  description = "Policy to allow EC2 instances to use KMS keys for decryption"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = [
          aws_kms_key.ec2_key.arn,
          aws_kms_key.secret_db_password_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_kms_access_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_kms_access_policy.arn
}

# Add KMS permissions to Lambda Role
resource "aws_iam_policy" "lambda_kms_access_policy" {
  name        = "Lambda_KMS_Access_Policy"
  description = "Policy to allow Lambda functions to use KMS keys for decryption"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ],
        Resource = [
          aws_kms_key.secret_email_credentials_key.arn
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_kms_access_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_access_policy.arn
}

# iam.tf

# IAM User for Administration
resource "aws_iam_user" "admin_user" {
  name = "AdminUser"

  tags = {
    Name = "AdminUser"
  }
}

# Optionally, attach administrative policies to this user
resource "aws_iam_user_policy_attachment" "admin_user_attach" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# iam.tf

# IAM Role for Administration
resource "aws_iam_role" "admin_role" {
  name = "AdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::084828563934:user/AdminUser"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "AdminRole"
  }
}

# Attach administrative policies to this role
resource "aws_iam_role_policy_attachment" "admin_role_attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Grants full access; adjust as needed
}

# iam.tf (continued)

# IAM Role for Key Administration
resource "aws_iam_role" "key_admin_role" {
  name = "KeyAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Effect    = "Allow",
      Principal = { AWS = aws_iam_user.admin_user.arn },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "KeyAdminRole"
  }
}

# IAM Policy for Key Administration
resource "aws_iam_policy" "key_admin_policy" {
  name        = "KeyAdminPolicy"
  description = "Policy to allow administration of KMS keys"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:GenerateDataKey*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the Policy to KeyAdminRole
resource "aws_iam_role_policy_attachment" "key_admin_policy_attach" {
  role       = aws_iam_role.key_admin_role.name
  policy_arn = aws_iam_policy.key_admin_policy.arn
}


# iam.tf

# IAM Role for RDS
resource "aws_iam_role" "rds_role" {
  name = "RDSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "RDSRole"
  }
}


resource "aws_iam_role" "s3_role" {
  name = "S3Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "S3Role"
  }
}
 