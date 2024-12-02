# random_password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%#!*&+-" # Exclude '@' and '/'
}
# Secret for Database Password
# secrets.tf

resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = var.db_password_secret_name
  description = "RDS database master password"

  kms_key_id = aws_kms_key.secret_db_password_key.arn

  tags = {
    Name = "csye6225-db-password-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}

# Secret for Email Service Credentials                                             
resource "aws_secretsmanager_secret" "email_credentials_secret" {
  name        = var.email_credentials_secret_name
  description = "Secret for Email Service Credentials"

  kms_key_id = aws_kms_key.secret_email_credentials_key.arn

  tags = {
    Name = "email-credentials-secret"
  }
}

resource "aws_secretsmanager_secret_version" "email_credentials_secret_version" {
  secret_id = aws_secretsmanager_secret.email_credentials_secret.id
  secret_string = jsonencode({
    sendgrid_api_key = var.sendgrid_api_key
    from_email       = var.from_email
  })
}