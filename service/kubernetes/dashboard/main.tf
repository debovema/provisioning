variable "connections" {
  type = "list"
}

variable "k8s_dashboard_user" {}
variable "k8s_dashboard_password" {}

variable "dummy_dependency" {}

resource "null_resource" "dashboard" {
  triggers {
    dummy_dependency = "${var.dummy_dependency}"
  }

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
      "htpasswd -bc /tmp/kubernetes-dashboard-basic-auth ${var.k8s_dashboard_user} ${var.k8s_dashboard_password}",
      "kubectl create secret generic kubernetes-dashboard-auth -n kube-system --from-file=/tmp/kubernetes-dashboard-basic-auth",
      "kubectl apply -Rf /tmp/dashboard",
    ]
  }
}
