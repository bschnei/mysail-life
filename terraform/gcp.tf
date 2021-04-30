provider "google" {

  # default project and region to apply to resources
  project     = "mysail-life"
  region      = "us-central1"

  credentials = file("terraform-sa-key.json")

}

# IP ADDRESS
resource "google_compute_address" "ip_address" {
  name = "${var.app_name}-ip"
}

# NETWORK
data "google_compute_network" "default" {
  name = "default"
}

# FIREWALL RULES
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-http"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["allow-https"]
}

# OS IMAGE
data "google_compute_image" "boot_image" {
  family  = "ubuntu-minimal-2104"
  project = "ubuntu-os-cloud"
}

# web server instance
resource "google_compute_instance" "web_server" {

  boot_disk {
    initialize_params {
      image = data.google_compute_image.boot_image.self_link
    }
  }

  # f1-micro is the smallest/cheapest instance gcp offers
  machine_type = "f1-micro"

  # this is a static hostname within the VPC
  # changing it requires a complete rebuild of the instance!
  name         = "web-server"

  zone         = "us-central1-a"

  # required. specifies the VPC
  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  tags = google_compute_firewall.allow_http.target_tags

  service_account {
    scopes = ["storage-ro"]
  }

  metadata = {
    ssh-keys = "ben:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDoYUV51feXIjctLJGZ5KCqDuxoNM4ryttu+L+IZiU36"
    user-data = file("cloud-init.conf")
  }
}
