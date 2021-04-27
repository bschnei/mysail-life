terraform {
    backend "gcs" {
        bucket = "mysail-life-terraform"
        prefix = "/state/mysail-life"
    }
    required_providers {
      google = {
        source  = "hashicorp/google"
        version = "~> 3.65.0"
      }
      mongodbatlas = {
        source  = "mongodb/mongodbatlas"
        version = "~> 0.8.2"
      }
      namecheap = {
        source  = "robgmills/namecheap"
        version = "~> 1.7.0"
        }
    }
}