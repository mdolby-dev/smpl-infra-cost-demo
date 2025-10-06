terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "my-test-project"
  region  = "us-central1"
}

# Spanner Instance
resource "google_spanner_instance" "example" {
  name         = "example-spanner-instance"
  config       = "regional-us-central1"
  display_name = "Example Spanner Instance"
  num_nodes    = 12  # This will affect the cost significantly
}

# Spanner Database
resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = "example-database"
}

# BigQuery Dataset
resource "google_bigquery_dataset" "example" {
  dataset_id  = "example_dataset"
  description = "Example dataset for cost testing"
  location    = "US"
}

# BigQuery Table
resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = "example_table"

  time_partitioning {
    type = "DAY"
  }

  # Schema definition
  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

# Pub/Sub Topic
resource "google_pubsub_topic" "example" {
  name = "example-topic"
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name

  message_retention_duration = "604800s"  # 7 days
  retain_acked_messages     = true
  ack_deadline_seconds      = 240
}

# Dataflow Job
resource "google_dataflow_job" "example" {
  name              = "example-dataflow-job"
  template_gcs_path = "gs://dataflow-templates/latest/Word_Count"
  temp_gcs_location = "gs://my-test-bucket/temp"
  
  parameters = {
    inputFile = "gs://dataflow-samples/shakespeare/kinglear.txt"
    output    = "gs://my-test-bucket/output"
  }

  machine_type = "n1-standard-32"  # This affects the compute cost
  max_workers  = 10                # This affects both compute and memory costs
}

# Storage Bucket for Dataflow
resource "google_storage_bucket" "dataflow_bucket" {
  name          = "my-test-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30  # days
    }
    action {
      type = "Delete"
    }
  }
}