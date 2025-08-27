output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.drupal_alb.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.drupal_db.endpoint
}

output "staging_instance_ips" {
  description = "Public IP addresses of staging instances"
  value       = aws_instance.staging_instances[*].public_ip
}

output "production_instance_ips" {
  description = "Public IP addresses of production instances"
  value       = aws_instance.production_instances[*].public_ip
}