provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

# cluster
resource "mongodbatlas_cluster" "mongo_cluster" {
  project_id = var.atlas_project_id
  name       = "${var.app_name}"

  provider_name               = "TENANT"
  backing_provider_name       = "GCP"
  provider_region_name        = "CENTRAL_US"
  provider_instance_size_name = "M2"
  disk_size_gb                = 2

  mongo_db_major_version       = "4.4"
  auto_scaling_disk_gb_enabled = false

}

# db user
resource "mongodbatlas_database_user" "mongo_user" {
  username           = "${var.app_name}-user"
  password           = var.atlas_user_password
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = var.app_name
  }
}

# ip access list
resource "mongodbatlas_project_ip_access_list" "mongo_ip_access_list" {
  project_id = var.atlas_project_id
  ip_address = google_compute_address.ipv4.address
  comment    = "GCP External IPv4"
}
