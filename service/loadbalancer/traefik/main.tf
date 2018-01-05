variable "domain" {}

variable "connections" {
  type = "list"
}

resource "null_resource" "traefik" {
  connection {
    host  = "${element(var.connections, 0)}" # execute on master node only
    user  = "root"
    agent = true
  }

  provisioner "file" {
    content     = "${data.template_file.traefik.rendered}"
    destination = "/tmp/traefik.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /tmp/traefik.yaml" 
    ]
  }
}

data "template_file" "traefik" {
  template = "${file("${path.module}/templates/traefik.yaml")}"

  vars {
    external_ip = "${element(var.connections, 0)}"
    domain_name = "${var.domain}"
  }
}
