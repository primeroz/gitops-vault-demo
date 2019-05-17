# This file contains all the interactions with Google Cloud
terraform {
  required_version = "= 0.11.13"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.1"
}

provider "google" {
  version     = "~> 2.6"
  region      = "${var.region}"
  credentials = "${file("/dev/shm/account.json")}"
}

provider "google-beta" {
  version     = "~> 2.6"
  region      = "${var.region}"
  credentials = "${file("/dev/shm/account.json")}"
}
