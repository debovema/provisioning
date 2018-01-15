variable "connections" {
  type = "list"
}

resource "null_resource" "dashboard" {
  connection {
    host  = "${element(var.connections, 0)}" # execute on master node only
    user  = "root"
    agent = true
  }

  provisioner "file" {
    source      = "service/kubernetes/dashboard/dashboard"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -Rf /tmp/dashboard"
    ]
  }
}
