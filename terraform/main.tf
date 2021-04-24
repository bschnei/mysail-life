terraform {
    backend "gcs" {
        bucket = "mysail-life-terraform"
        prefix = "/state/mysail-life"
    }
    required_providers {
      cloudflare = {
          source  = "cloudflare/cloudflare"
          version = "~> 2.19.2"
      }
      google = {
          source  = "hashicorp/google"
          version = "~> 3.63.0"
      }
      mongodbatlas = {
          source  = "mongodb/mongodbatlas"
          version = "~> 0.8.2"
      }
    }
}