# Route 53 A record for EC2 instance using aws_profile as the environment prefix
resource "aws_route53_record" "app_a_record" {
  zone_id = var.route53_zone_id                     # Hosted Zone ID from variables.tf
  name    = "${var.domain_name}"  
  type    = "A"
  ttl     = 300
  records = [aws_instance.app_instance_ud.public_ip] # Points to the EC2 instance's public IP

  depends_on = [aws_instance.app_instance_ud] # Ensures EC2 is created before the record

 
}