module "provider" {
  source = "./provider/scaleway"

  organization    = "${var.scaleway_organization}"
  token           = "${var.scaleway_token}"
  hosts           = "${var.hosts}"
  hostname_format = "${var.hostname_format}"
  region          = "${var.scaleway_region}"
}

/*
module "provider" {
  source = "./provider/digitalocean"

  token           = "${var.digitalocean_token}"
  ssh_keys        = "${var.digitalocean_ssh_keys}"
  hosts           = "${var.hosts}"
  hostname_format = "${var.hostname_format}"
  region          = "${var.digitalocean_region}"
}
*/

module "dns" {
  source = "./dns/gandi"

  count      = "${var.hosts}"
  domain     = "${var.domain}"
  api_key    = "${var.gandi_api_key}"
  public_ips = "${module.provider.public_ips}"
  hostnames  = "${module.provider.hostnames}"
}

/*
module "dns" {
  source = "./dns/aws"

  count      = "${var.hosts}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
  domain     = "${var.domain}"
  public_ips = "${module.provider.public_ips}"
  hostnames  = "${module.provider.hostnames}"
}
*/

/*
module "dns" {
  source = "./dns/cloudflare"

  count      = "${var.hosts}"
  email      = "${var.cloudflare_email}"
  token      = "${var.cloudflare_token}"
  domain     = "${var.domain}"
  public_ips = "${module.provider.public_ips}"
  hostnames  = "${module.provider.hostnames}"
}
*/

/*
module "dns" {
  source = "./dns/google"

  count        = "${var.hosts}"
  project      = "${var.google_project}"
  region       = "${var.google_region}"
  creds_file   = "${var.google_credentials_file}"
  managed_zone = "${var.google_managed_zone}"
  domain       = "${var.domain}"
  public_ips   = "${module.provider.public_ips}"
  hostnames    = "${module.provider.hostnames}"
}
*/

module "wireguard" {
  source = "./security/wireguard"

  count       = "${var.hosts}"
  connections = "${module.provider.public_ips}"
  private_ips = "${module.provider.private_ips}"
  hostnames   = "${module.provider.hostnames}"
  pod_subnet  = "${var.kubernetes_pod_subnet}"
}

module "firewall" {
  source = "./security/ufw"

  count                = "${var.hosts}"
  connections          = "${module.provider.public_ips}"
  private_interface    = "${module.provider.private_network_interface}"
  vpn_interface        = "${module.wireguard.vpn_interface}"
  vpn_port             = "${module.wireguard.vpn_port}"
  kubernetes_interface = "${module.kubernetes.overlay_interface}"
}

module "etcd" {
  source = "./service/etcd"

  count       = "${var.hosts}"
  connections = "${module.provider.public_ips}"
  hostnames   = "${module.provider.hostnames}"
  vpn_unit    = "${module.wireguard.vpn_unit}"
  vpn_ips     = "${module.wireguard.vpn_ips}"
}

module "kubernetes" {
  source = "./service/kubernetes"

  count          = "${var.hosts}"
  connections    = "${module.provider.public_ips}"
  cluster_name   = "${var.domain}"
  vpn_ips        = "${module.wireguard.vpn_ips}"
  etcd_endpoints = "${module.etcd.endpoints}"
  pod_subnet     = "${var.kubernetes_pod_subnet}"
  service_subnet = "${var.kubernetes_service_subnet}"
}

module "misc" {
  source = "./service/misc"

  count       = "${var.hosts}"
  connections = "${module.provider.public_ips}"
  dependency  = "${module.kubernetes.overlay_interface}"
}

module "dashboard" {
  source = "./service/kubernetes/dashboard"

  connections = "${module.provider.public_ips}"
}

module "loadbalancer" {
  source = "./service/loadbalancer/traefik"

  dependency  = "${module.kubernetes.overlay_interface}"
  domain      = "${var.domain}"
  connections = "${module.provider.public_ips}"
  lb_user     = "${var.lb_user}"
  lb_password = "${var.lb_password}"
  le_mail     = "${var.le_mail}"
  le_staging  = "${var.le_staging}"
}
