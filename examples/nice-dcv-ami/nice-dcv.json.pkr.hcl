# This file was autogenerated by the BETA 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/from-1.5/variables#type-constraints for more info.
variable "aws_region" {
  type = string
}

variable "ca_public_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/ca.crt.pem"
}

variable "consul_download_url" {
  type    = string
  default = ""
}

variable "consul_module_version" {
  type    = string
  default = "v0.8.0"
}

variable "consul_version" {
  type    = string
  default = "1.8.4"
}

variable "install_auth_signing_script" {
  type    = string
  default = "true"
}


variable "vault_download_url" {
  type    = string
  default = ""
}

variable "vault_version" {
  type    = string
  default = "1.5.5"
}

locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  template_dir = path.root
}


source "amazon-ebs" "amazonlinux2-nicedcv-nvidia-ami" {
  ami_description = "A Remote Workstation NICE DCV NVIDIA Cent OS 7 AMI that will accept connections from hosts with TLS Certs."
  ami_name        = "firehawk-amazonlinux2-nicedcv-nvidia-ami-${local.timestamp}-{{uuid}}"
  instance_type   = "g3s.xlarge"
  region          = "${var.aws_region}"
  source_ami_filter {
    filters = {
      name         = "DCV-AmazonLinux2-2020-1-9012-NVIDIA-450-51-05-x86-64"
    }
    most_recent = true
    owners      = ["877902723034"]
  }
  ssh_username    = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.amazonlinux2-nicedcv-nvidia-ami"]

  provisioner "shell" {
    inline = ["mkdir -p /tmp/terraform-aws-vault/modules"]
  }

  provisioner "file" {
    destination = "/tmp/terraform-aws-vault/modules"
    source      = "${local.template_dir}/../../modules/"
  }

  provisioner "shell" { # Vault client probably wont be install on bastions in future, but most hosts that will authenticate will require it.
    inline = [
      "if test -n '${var.vault_download_url}'; then",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --download-url ${var.vault_download_url};",
      "else",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --version ${var.vault_version};",
      "fi"
      ]
  }

  provisioner "file" {
    destination = "/tmp/sign-request.py"
    source      = "${local.template_dir}/auth/sign-request.py"
  }
  provisioner "file" {
    destination = "/tmp/ca.crt.pem"
    source      = "${var.ca_public_key_path}"
  }
  # provisioner "file" { # vault and consul servers only: clients dont need the private and public keys.
  #   destination = "/tmp/vault.crt.pem"
  #   source      = "${var.tls_public_key_path}"
  # }
  # provisioner "file" { # vault and consul servers only: clients dont need the private and public keys.
  #   destination = "/tmp/vault.key.pem"
  #   source      = "${var.tls_private_key_path}"
  # }
  provisioner "shell" {
    inline         = [
      "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
      "sudo mv /tmp/sign-request.py /opt/vault/scripts/",
      "else",
      "sudo rm /tmp/sign-request.py",
      "fi",
      "sudo mv /tmp/ca.crt.pem /opt/vault/tls/",
      # "sudo mv /tmp/vault.crt.pem /opt/vault/tls/", # vault and consul servers only: clients dont need the private and public keys.
      # "sudo mv /tmp/vault.key.pem /opt/vault/tls/", # vault and consul servers only: clients dont need the private and public keys.
      "sudo chown -R vault:vault /opt/vault/tls/",
      "sudo chmod -R 600 /opt/vault/tls",
      "sudo chmod 700 /opt/vault/tls",
      "sudo /tmp/terraform-aws-vault/modules/update-certificate-store/update-certificate-store --cert-file-path /opt/vault/tls/ca.crt.pem"]
    inline_shebang = "/bin/bash -e"
  }
  provisioner "shell" {
    inline         = ["sudo apt-get install -y git",
      "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
      "sudo apt-get install -y python-pip",
      "LC_ALL=C && sudo pip install boto3",
      "fi"]
    inline_shebang = "/bin/bash -e"
    only           = ["amazon-ebs.ubuntu16-ami", "amazon-ebs.ubuntu18-ami"]
  }
  provisioner "shell" {
    inline = ["sudo yum install -y git",
      "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
      "sudo yum install -y python2-pip",
      "LC_ALL=C && sudo pip install boto3",
      "fi"]
    only   = ["amazon-ebs.amazonlinux2-nicedcv-nvidia-ami"]
  }
  provisioner "shell" {
    inline = [
      "git clone --branch ${var.consul_module_version} https://github.com/hashicorp/terraform-aws-consul.git /tmp/terraform-aws-consul",
      "if test -n \"${var.consul_download_url}\"; then",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --download-url ${var.consul_download_url};",
      "else",
      " /tmp/terraform-aws-consul/modules/install-consul/install-consul --version ${var.consul_version};",
      "fi"]
  }
  provisioner "shell" {
    inline = ["/tmp/terraform-aws-consul/modules/install-dnsmasq/install-dnsmasq"]
    only   = ["amazon-ebs.ubuntu16-ami", "amazon-ebs.amazonlinux2-nicedcv-nvidia-ami"]
  }
  provisioner "shell" {
    inline = ["/tmp/terraform-aws-consul/modules/setup-systemd-resolved/setup-systemd-resolved"]
    only   = ["amazon-ebs.ubuntu18-ami"]
  }

  provisioner "shell" { # Ensure the NICE DCV session starts automatically on boot.
    inline = [
      "sudo sed -i \"s/#create-session =.*/create-session = true/g\" /etc/dcv/dcv.conf"
      "sudo sed -i \"s/#owner =.*/owner = 'ec2-user'/g\" /etc/dcv/dcv.conf",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }

  post-processor "manifest" {
      output = "${local.template_dir}/manifest.json"
      strip_path = true
      custom_data = {
        timestamp = "${local.timestamp}"
      }
  }
}
