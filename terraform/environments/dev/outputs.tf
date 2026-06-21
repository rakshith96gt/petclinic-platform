output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.dns.certificate_arn
}

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.dns.zone_id
}
