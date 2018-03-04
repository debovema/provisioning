variable "count" {}

variable "connections" {
  type = "list"
}

variable "dependency" {}

resource "null_resource" "rook" {
  triggers {
    dummy_dependency = "${var.dependency}"
  }

  connection {
    host  = "${element(var.connections, 0)}" # execute on master node only
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/rook",
      "mkdir /tmp/rook"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/templates/"
    destination = "/tmp/rook/"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/rook-install.sh"
  }
}

