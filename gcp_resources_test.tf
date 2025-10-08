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
  ack_deadline_seconds      = 2400
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
  max_workers  = 100                # This affects both compute and memory costs
}

# Storage Bucket for Dataflow
resource "google_storage_bucket" "dataflow_bucket" {
  name          = "my-test-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 120  # days
    }
    action {
      type = "Delete"
    }
  }
}

# Global storage bucket
resource "google_storage_bucket" "global_bucket" {
  name          = "my-global-bucket"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Pub/Sub DR storage bucket - us-central1
resource "google_storage_bucket" "pubsub_dr_us_central1" {
  name          = "pubsub-dr-us-central1"
  location      = "us-central1"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Pub/Sub DR storage bucket - us-west1
resource "google_storage_bucket" "pubsub_dr_us_west1" {
  name          = "pubsub-dr-us-west1"
  location      = "us-west1"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Firestore database (Native mode) in nam5
resource "google_firestore_database" "nam5" {
  name        = "(default)"
  location_id = "nam5"
  type        = "NATIVE"
}

# Storage bucket for Firestore backups (7-day retention)
resource "google_storage_bucket" "firestore_backups_nam5" {
  name          = "firestore-backups-nam5"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Pub/Sub Dead-Letter Queue (DLQ) topic
resource "google_pubsub_topic" "example_dlq" {
  name = "example-dlq-topic"
}

# Additional subscribers to the existing topic for cost testing
resource "google_pubsub_subscription" "subscriber_a" {
  name  = "example-sub-a"
  topic = google_pubsub_topic.example.name

  ack_deadline_seconds       = 600
  message_retention_duration = "604800s"  # 7 days
  retain_acked_messages      = false
}

resource "google_pubsub_subscription" "subscriber_b" {
  name  = "example-sub-b"
  topic = google_pubsub_topic.example.name

  ack_deadline_seconds       = 600
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  dead_letter_policy {
    dead_letter_topic      = google_pubsub_topic.example_dlq.id
    max_delivery_attempts  = 5
  }
}

resource "google_pubsub_subscription" "subscriber_c" {
  name  = "example-sub-c"
  topic = google_pubsub_topic.example.name

  ack_deadline_seconds       = 600
  message_retention_duration = "604800s"
  retain_acked_messages      = false
}

# Managed GKE cluster - regional (us-central1)
resource "google_container_cluster" "gke_us_central1" {
  name     = "gke-us-central1"
  location = "us-central1"

  remove_default_node_pool = false
  initial_node_count       = 12

  node_config {
    machine_type = "e2-standard-4"
    preemptible  = false
    disk_size_gb  = 100
  }

  # Enable basic add-ons useful for demos
  addons_config {
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = false
    }
  }
}

# Managed GKE cluster - regional (us-west1)
resource "google_container_cluster" "gke_us_west1" {
  name     = "gke-us-west1"
  location = "us-west1"

  remove_default_node_pool = false
  initial_node_count       = 12

  node_config {
    machine_type = "e2-standard-4"
    preemptible  = false
    disk_size_gb  = 1000
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = false
    }
  }
}