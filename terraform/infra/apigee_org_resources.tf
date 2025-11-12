locals {
  # FOR EVALUATION, allocate a /28 for management and runtime.
  # For PAID ORGS, allocate a /22 for runtime and a /28 for management.
  # Assumes that service_networking_peering_cidr is a /20 CIDR block.

  #EVAL
  # /28 for runtime
  apigee_runtime_cidr_range = cidrsubnet(var.service_networking_peering_cidr, 8, 0) # 10.21.0.0/28
  apigee_mgmt_cidr_range    = cidrsubnet(var.service_networking_peering_cidr, 8, 1) # 10.21.0.16/28
}

# Apigee organization
resource "google_apigee_organization" "apigee_org" {

  project_id          = data.google_project.apigee.project_id
  display_name        = "Apigee Organization for ${data.google_project.apigee.project_id}"
  description         = "Apigee Organization created via Terraform for DEV environment"
  analytics_region    = var.region
  disable_vpc_peering = false
  authorized_network  = google_compute_network.apigee_vpc.id
  runtime_type        = "CLOUD"

  # For testing purposes, we can use EVALUATION billing type
  billing_type = "EVALUATION"
  retention    = "MINIMUM"

  # billing_type = "SUBSCRIPTION"
  # retention = "DELETION_RETENTION_UNSPECIFIED"

  lifecycle {
    prevent_destroy = true
  }


  # This is Gemini hallucination!!!

  # properties {
  #   property {
  #     name  = "analytics.bigquery.exportDataset"
  #     value = google_bigquery_dataset.apigee_analytics.dataset_id
  #   }
  #   property {
  #     name = "features.hybrid.enabled"
  #     value = "true"
  #   }
  # }

  #   # The key property that enables export to BigQuery
  # properties = [
  #   property {
  #   name = "analytics.bigquery.exportDataset"
  #   value = google_bigquery_dataset.apigee_analytics.dataset_id
  # }]

  depends_on = [
    google_service_networking_connection.apigee_private_connection,
    google_project_service.apigee
  ]
}

# Apigee instance
resource "google_apigee_instance" "apigee_instance" {

  name     = "eval-instance"
  location = var.region
  org_id   = google_apigee_organization.apigee_org.id

  # Uncomment the following line to specify a the CIDR ranges, otherwise Apigee will auto allocate from the Service Networking peering range
  # ip_range = "10.21.0.0/28,10.21.0.16/28"
  ip_range = "${local.apigee_runtime_cidr_range},${local.apigee_mgmt_cidr_range}"

  consumer_accept_list = [
    "${var.apigee_project_id}",
    "${var.host_project_id}"
  ]
}

# Apigee environments and groups
resource "google_apigee_environment" "env" {

  for_each = {
    for env in var.environments : env.name => env
  }

  name        = each.value.name
  description = each.value.description
  org_id      = google_apigee_organization.apigee_org.id
}

resource "google_apigee_envgroup" "envgroup" {

  for_each = {
    for env in var.environments : env.name => env
  }

  name      = "${each.value.name}-group"
  org_id    = google_apigee_organization.apigee_org.id
  hostnames = each.value.hostnames
}


# Attach environments to environment groups
# Note. Eval Orgs only support a maximum of two environments and environment groups

resource "google_apigee_envgroup_attachment" "envgroup_attachment" {

  for_each = {
    for env in var.environments : env.name => env
  }
  envgroup_id = google_apigee_envgroup.envgroup[each.value.name].id
  environment = google_apigee_environment.env[each.value.name].name
}

# Attach environments to instance
# This sometimes doesn't work for Evaluation Instances

resource "google_apigee_instance_attachment" "instance_attachment" {

  for_each = {
    for env in var.environments : env.name => env
  }
  instance_id = google_apigee_instance.apigee_instance.id
  environment = google_apigee_environment.env[each.value.name].name
}

resource "google_bigquery_dataset" "apigee_analytics" {
  dataset_id = var.dataset_name
  project    = var.apigee_project_id
  location   = var.region

  depends_on = [google_project_service.bigquery]
}

output "bq_dataset" {
  value = google_bigquery_dataset.apigee_analytics.dataset_id
}

# Bind Apigee's service account to the dataset
resource "google_bigquery_dataset_iam_member" "apigee_writer" {
  dataset_id = google_bigquery_dataset.apigee_analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.apigee.number}@gcp-sa-apigee.iam.gserviceaccount.com"
}


resource "null_resource" "apigee_bq_datastore" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      echo "Checking for existing Apigee analytics BigQuery datastore..."

      ACCESS_TOKEN=$(gcloud auth print-access-token)
      DATASTORE_NAME=bigquery-export

      # Query existing datastores
      RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://apigee.googleapis.com/v1/organizations/${var.apigee_project_id}/analytics/datastores")

      EXISTS=$(echo "$RESPONSE" | jq -r '.datastores[]?.name' | grep -x "$DATASTORE_NAME" || true)

      if [ -z "$EXISTS" ]; then
      curl -X POST "https://apigee.googleapis.com/v1/organizations/${var.apigee_project_id}/analytics/datastores" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "$DATASTORE_NAME",
          "targetType": "bigquery",
          "datastoreConfig": {
            "projectId": "${var.apigee_project_id}",
            "datasetName": "${google_bigquery_dataset.apigee_analytics.dataset_id}",
            "tablePrefix": "apigee"
          }
        }' \
          | jq .
        echo "✅ BigQuery datastore configured."
      else
        echo "✅ BigQuery datastore already exists — skipping creation."
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      echo "Deleting Apigee analytics BigQuery datastore..."
      ACCESS_TOKEN=$(gcloud auth print-access-token)
      curl -s -X DELETE \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://apigee.googleapis.com/v1/organizations/${self.triggers.org}/analytics/datastores/$DATASTORE_NAME" || true
      echo "✅ Datastore deletion attempted (ignored if missing)."
    EOT
  }

  triggers = {
    dataset = var.dataset_name
    org = var.apigee_project_id
  }
}