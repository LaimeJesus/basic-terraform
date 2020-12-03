data "digitalocean_ssh_key" "do_ssh_key" {
  name = var.DO_SSH_KEY_NAME
}
