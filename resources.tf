
# Droplet
resource "digitalocean_droplet" "www" {
    image = "ubuntu-18-04-x64"
    name = "www"
    region = "nyc1"
    size = "s-1vcpu-1gb"
    private_networking = true
    ssh_keys = [
      data.digitalocean_ssh_key.do_ssh_key.id
    ]

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.PVT_KEY_PATH)
        timeout = "2m"
    }
    provisioner "remote-exec" {
        inline = [
            "export PATH=$PATH:/usr/bin",
            # install nginx
            "sudo apt-get update",
            "sudo apt-get -y install nginx"
        ]
    }
}

# LoadBalancer
resource "digitalocean_loadbalancer" "www-lb" {
  name = "www-lb"
  region = "nyc1"

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.www.id]
}

# Domain
resource "digitalocean_domain" "default" {
   name = var.DOMAIN
   ip_address = digitalocean_loadbalancer.www-lb.ip
}
