variable "DO_PAT" {
  description = "This Variable contains the Personal Access Token from a Digital Ocean Account"
}

variable "PVT_KEY" {
  description = "This Variable contains the SSH Public Key from a Digital Ocean Account"
}

# define the digitalocean provider to be used
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
    }
  }
}

# add access token as token in the DO provider
provider "digitalocean" {
  token = var.DO_PAT
}

# add this variable into droplets
data "digitalocean_ssh_key" "digitalocean" {
  name = "digitalocean"
}
