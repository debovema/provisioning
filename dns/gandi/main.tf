variable "count" {}

variable "api_key" {}

variable "domain" {}

variable "hostnames" {
  type = "list"
}

variable "public_ips" {
  type = "list"
}

provider "gandi" {
  key = "${var.api_key}"
}

resource "gandi_zone" "zone" {
  name = "${var.domain} zone"
}

resource "gandi_zonerecord" "kubernetes_wildcard" {
  zone = "${gandi_zone.zone.id}"
  name = "*.kub2"
  type = "A"
  ttl = 600
  values = [
    "${element(var.public_ips, 0)}"
  ]
}

resource "gandi_domainattachment" "gandi_domainattachment" {
  domain = "${var.domain}"
  zone = "${gandi_zone.zone.id}"
}

