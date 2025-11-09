output "apigee_org" {
  value = google_apigee_organization.apigee_org.id
}

output "apigee_service_attachment" {
  value = google_apigee_instance.apigee_instance.service_attachment
}