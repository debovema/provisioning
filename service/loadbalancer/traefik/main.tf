variable "domain" {}
variable "dependency" {}
variable "le_mail" {}
variable "le_staging" {}

variable "connections" {
  type = "list"
}

resource "null_resource" "traefik" {
  connection {
    host  = "${element(var.connections, 0)}" # execute on master node only
    user  = "root"
    agent = true
  }

  # ensure an acme.json file exists
  provisioner "local-exec" {
    command = "touch service/loadbalancer/traefik/acme.json"
  }

  # copy optional ACME file to avoid regeneration of Let's Encrypt certificates
  provisioner "file" {
    source      = "service/loadbalancer/traefik/acme.json"
    destination = "/srv/acme.json"
  }

  provisioner "file" {
    content     = "${data.template_file.traefik.rendered}"
    destination = "/tmp/traefik.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.dependency}",
      "kubectl apply -f /tmp/traefik.yaml" 
    ]
  }
}

data "template_file" "traefik" {
  template = "${file("${path.module}/templates/traefik.yaml")}"

  vars {
    external_ip = "${element(var.connections, 0)}"
    domain_name = "${var.domain}"
    le_mail     = "${var.le_mail}"
    le_server   = "${var.le_staging ? \"https://acme-staging.api.letsencrypt.org/directory\" : \"\"}"
  }
}
