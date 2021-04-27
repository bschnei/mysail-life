provider "namecheap" {
  username = var.namecheap_username
  api_user = var.namecheap_username
  token = var.namecheap_token
  ip = var.namecheap_ip
  use_sandbox = false
}

# DNS A record
resource "namecheap_record" "ipv4_record" {
  name = "@"
  domain = var.domain
  address = google_compute_address.ip_address.address
  type = "A"
}
