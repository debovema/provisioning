variable "count" {}
variable "dependency" {}

variable "connections" {
  type = "list"
}

resource "null_resource" "zsh" {
  count = "${var.count}"

  connection {
    host  = "${element(var.connections, count.index)}" # execute on all nodes
    user  = "root"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > /tmp/ohmyz.sh",
      "sed -i 's|env zsh|#env zsh|' /tmp/ohmyz.sh",
      "sed -i 's|git clone|git clone -q|' /tmp/ohmyz.sh",
      "chmod u+x /tmp/ohmyz.sh",
      ". /tmp/ohmyz.sh",
      "sed -ie 's|ZSH_THEME=\".*\"|ZSH_THEME=\"ys\"|' /root/.zshrc"
    ]
  }
}
