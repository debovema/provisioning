variable "domain" {}
variable "dependency" {}
variable "lb_user" {}
variable "lb_password" {}
variable "le_mail" {}
variable "le_staging" {}
variable "le_prod_server" {
  default = ""
}
variable "le_staging_server" {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

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
    command = "touch ${path.module}/acme.json"
  }

  # copy optional ACME file to avoid regeneration of Let's Encrypt certificates
  provisioner "file" {
    source      = "${path.module}/acme.json"
    destination = "/srv/acme.json"
  }

  provisioner "file" {
    content     = "${data.template_file.traefik.rendered}"
    destination = "/tmp/traefik.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.dependency} > /dev/null",
      "htpasswd -bc /tmp/traefik-basic-auth ${var.lb_user} ${var.lb_password}",
      "kubectl create namespace traefik",
      "kubectl create secret generic traefik-dashboard-auth -n traefik --from-file=/tmp/traefik-basic-auth",
      "kubectl apply -f /tmp/traefik.yaml"
    ]
  }
}

data "template_file" "traefik" {
  template = "${file("${path.module}/templates/traefik.yaml")}"

  vars {
    external_ip = "${element(var.connections, 0)}"
    domain_name = "${var.domain}"
    dependency  = "${var.dependency}"
    le_mail     = "${var.le_mail}"
    le_server   = "${var.le_staging ? var.le_staging_server : var.le_prod_server}"
  }
}

output "traefik_installed" {
  value = "${null_resource.traefik.id}"
}

