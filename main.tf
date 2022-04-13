//define a variable with list of GCP services to be enabled
variable "gcp_service_list" {
  description ="The list of apis necessary for the demo"
  type = list(string)
  default = ["bigquery.googleapis.com",
            "bigqueryconnection.googleapis.com",
            "bigquerystorage.googleapis.com",
            "storage-component.googleapis.com",
            "storage-api.googleapis.com"]
}

//datasource to collect project info 
data "google_project" "project" {
}

//module to enable the required GCP services
resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  service = each.key
  disable_dependent_services = true
}


resource "random_uuid" "test" {
}

//module to create GCS bucket for hosting data files
resource "google_storage_bucket" "bucket" {
  name   = "bigsearch-${random_uuid.test.result}"
  location = "US"
  uniform_bucket_level_access = true
  depends_on = [
    google_project_service.gcp_services
  ]
}

//module to load datafiles into the GCS bucket
resource "google_storage_bucket_object" "datafiles" {
  
  for_each = fileset("./datasets/","*")
  name = "${each.value}"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "./datasets/${each.value}"
  depends_on = [
    google_storage_bucket.bucket
  ]
}

//module to create a bq dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "bigsearch_demo"
  friendly_name               = "demo"
  description                 = "This is a bigsearch demo dataset"
  location                    = "US"
  delete_contents_on_destroy  = true
    depends_on = [
    google_project_service.gcp_services
  ]
}

// create a bq table in the above dataset
resource "google_bigquery_table" "table" {
  deletion_protection = false
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "log_data"
}

//module to load log files into a BQ table
resource "google_bigquery_job" "job" {
  job_id     = "job-${random_uuid.test.result}"

  load {
      
    source_uris = [
      "gs://${google_storage_bucket.bucket.name}/logfile.csv"
    ]
    source_format = "CSV"

    destination_table {
      project_id = google_bigquery_table.table.project
      dataset_id = google_bigquery_table.table.dataset_id
      table_id   = google_bigquery_table.table.table_id
    }

    skip_leading_rows = 1
    schema_update_options = ["ALLOW_FIELD_RELAXATION", "ALLOW_FIELD_ADDITION"]

    write_disposition = "WRITE_APPEND"
    autodetect = true
  }

  depends_on = [
    google_project_service.gcp_services
  ]
}