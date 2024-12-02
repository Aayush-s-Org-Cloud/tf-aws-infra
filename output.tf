# kms.tf (continued)

output "ec2_kms_key_arn" {
  value = aws_kms_key.ec2_key.arn
}

output "rds_kms_key_arn" {
  value = aws_kms_key.rds_key.arn
}



output "secret_db_password_kms_key_arn" {
  value = aws_kms_key.secret_db_password_key.arn
}

output "secret_email_credentials_kms_key_arn" {
  value = aws_kms_key.secret_email_credentials_key.arn
}