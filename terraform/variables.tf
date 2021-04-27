### GENERAL
variable "app_name" {
  type = string
}

### ATLAS
variable "atlas_project_id" {
  type = string
}

variable "atlas_public_key" {
  type = string
}

variable "atlas_private_key" {
  type = string
}

variable "atlas_user_password" {
  type = string
}

### GCP
variable "gcp_machine_type" {
  type = string
}

### NAMECHEAP
variable "namecheap_username" {
  type = string
}

variable "namecheap_token" {
  type = string
}

variable "namecheap_ip" {
  type = string
}

variable "domain" {
  type = string
}