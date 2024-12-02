resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-ec2-key-policy",
    Statement : [
      {
        Sid : "Allow administration of the key",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.key_admin_role.arn
        },
        Action : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"

        ],
        Resource : "*"
      },
      {
        Sid : "Allow use of the key by EC2",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.ec2_role.arn
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow attachment of persistent resources",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.ec2_role.arn
        },
        Action : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:GenerateDataKey*",
          "kms:RevokeGrant"
        ],
        Resource : "*",
        Condition : {
          Bool : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        Sid : "Allow account root user full access",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })

  tags = {
    Name = "ec2-kms-key"
  }

  depends_on = [
    aws_iam_role.key_admin_role,
    aws_iam_role.ec2_role
  ]
}
# KMS Alias for EC2 Key
resource "aws_kms_alias" "ec2_alias" {
  name          = "alias/ec2-kms-key"
  target_key_id = aws_kms_key.ec2_key.id
}
# KMS Key for RDS  
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-rds-key-policy",
    Statement : [
      {
        Sid : "Allow administration of the key",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.key_admin_role.arn
        },
        Action : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:GenerateDataKey*",
          "kms:Delete*"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow use of the key by RDS",
        Effect : "Allow",
        Principal : {
          AWS : "*"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow attachment of persistent resources",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.rds_role.arn
        },
        Action : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource : "*",
        Condition : {
          Bool : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        Sid : "Allow account root user full access",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })

  tags = {
    Name = "rds-kms-key"
  }

  depends_on = [
    aws_iam_role.key_admin_role,
    aws_iam_role.rds_role
  ]
}
# KMS Alias for RDS Key
resource "aws_kms_alias" "rds_alias" {
  name          = "alias/rds-kms-key"
  target_key_id = aws_kms_key.rds_key.id
}

# KMS Key for S3  


resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-s3-key-policy",
    Statement : [
      {
        Sid : "Allow administration of the key",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.key_admin_role.arn
        },
        Action : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:GenerateDataKey*",
          "kms:Delete*"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow use of the key by S3",
        Effect : "Allow",
        Principal : {
          AWS : "*"
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*",

      },
      {
        Sid : "Allow attachment of persistent resources",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.s3_role.arn
        },
        Action : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource : "*",
        Condition : {
          Bool : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        Sid : "Allow account root user full access",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })

  tags = {
    Name = "s3-kms-key"
  }

  depends_on = [
    aws_iam_role.key_admin_role,
    aws_iam_role.s3_role
  ]
}

# KMS Alias for S3 Key
resource "aws_kms_alias" "s3_alias" {
  name          = "alias/s3-kms-key"
  target_key_id = aws_kms_key.s3_key.id
}

# kms_db_password.tf

resource "aws_kms_key" "secret_db_password_key" {
  description             = "KMS key for Database Password in Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-secret-db-password-policy",
    Statement : [
      {
        Sid : "Allow administration of the key",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.key_admin_role.arn
        },
        Action : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:GenerateDataKey*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow use of the key by EC2 and Lambda",
        Effect : "Allow",
        Principal : {
          AWS : [
            aws_iam_role.ec2_role.arn,        # EC2 IAM Role ARN
            aws_iam_role.lambda_exec_role.arn # Lambda Execution Role ARN
          ]
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow attachment of persistent resources",
        Effect : "Allow",
        Principal : {
          AWS : [
            aws_iam_role.ec2_role.arn,        # EC2 IAM Role ARN
            aws_iam_role.lambda_exec_role.arn # Lambda Execution Role ARN
          ]
        },
        Action : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource : "*",
        Condition : {
          Bool : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        Sid : "Allow account root user full access",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })

  tags = {
    Name = "secret-db-password-kms-key"
  }

  depends_on = [
    aws_iam_role.key_admin_role,
    aws_iam_role.ec2_role,
    aws_iam_role.lambda_exec_role
  ]
}

# KMS Alias for Secrets Manager (Database Password) Key
resource "aws_kms_alias" "secret_db_password_alias" {
  name          = "alias/secret-db-password-kms-key"
  target_key_id = aws_kms_key.secret_db_password_key.id
}

# kms_email_credentials.tf

resource "aws_kms_key" "secret_email_credentials_key" {
  description             = "KMS key for Email Credentials in Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-secret-email-credentials-policy",
    Statement : [
      {
        Sid : "Allow administration of the key",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.key_admin_role.arn
        },
        Action : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:GenerateDataKey*",
          "kms:Get*",
          "kms:Delete*"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow use of the key by Lambda",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.lambda_exec_role.arn # Lambda Execution Role ARN
        },
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource : "*"
      },
      {
        Sid : "Allow attachment of persistent resources",
        Effect : "Allow",
        Principal : {
          AWS : aws_iam_role.lambda_exec_role.arn # Lambda Execution Role ARN
        },
        Action : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource : "*",
        Condition : {
          Bool : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        Sid : "Allow account root user full access",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })

  tags = {
    Name = "secret-email-credentials-kms-key"
  }

  depends_on = [
    aws_iam_role.key_admin_role,
    aws_iam_role.lambda_exec_role
  ]
}

# KMS Alias for Secrets Manager (Email Credentials) Key
resource "aws_kms_alias" "secret_email_credentials_alias" {
  name          = "alias/secret-email-credentials-kms-key"
  target_key_id = aws_kms_key.secret_email_credentials_key.id
}



