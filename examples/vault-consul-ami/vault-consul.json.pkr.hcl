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
  type    = string
  # default = "${var.AWS_DEFAULT_REGION}"
}

variable "ca_public_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/ca.crt.pem"
}

variable "consul_download_url" {
  type    = string
  # default = "${var.CONSUL_DOWNLOAD_URL}"
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

variable "tls_private_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/vault.key.pem"
}

variable "tls_public_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/vault.crt.pem"
}

variable "vault_download_url" {
  type    = string
  default = ""
}

variable "vault_version" {
  type    = string
  default = "1.5.5"
}

# "timestamp" template function replacement
locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  template_dir = path.root
}

source "amazon-ebs" "amazon-linux-2-ami" {
  ami_description = "An Amazon Linux 2 AMI that has Vault ${var.vault_version} and Consul ${var.consul_version} installed."
  ami_name        = "vault-consul-amazon-linux-2-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami_filter {
    filters = {
      architecture                       = "x86_64"
      "block-device-mapping.volume-type" = "gp2"
      name                               = "*amzn2-ami-hvm-*"
      root-device-type                   = "ebs"
      virtualization-type                = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

source "amazon-ebs" "ubuntu16-ami" {
  ami_description = "An Ubuntu 16.04 AMI that has Vault ${var.vault_version} and Consul ${var.consul_version} installed."
  ami_name        = "vault-consul-ubuntu16-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami_filter {
    filters = {
      architecture                       = "x86_64"
      "block-device-mapping.volume-type" = "gp2"
      name                               = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
      root-device-type                   = "ebs"
      virtualization-type                = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

source "amazon-ebs" "ubuntu18-ami" {
  ami_description = "An Ubuntu 18.04 AMI that has Vault ${var.vault_version} and Consul ${var.consul_version} installed."
  ami_name        = "vault-consul-ubuntu18-${local.timestamp}-{{uuid}}"
  instance_type   = "t2.micro"
  region          = "${var.aws_region}"
  source_ami_filter {
    filters = {
      architecture                       = "x86_64"
      "block-device-mapping.volume-type" = "gp2"
      name                               = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
      root-device-type                   = "ebs"
      virtualization-type                = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.amazon-linux-2-ami", "source.amazon-ebs.ubuntu16-ami", "source.amazon-ebs.ubuntu18-ami"]

  provisioner "shell" {
    inline = ["mkdir -p /tmp/terraform-aws-vault/modules"]
  }

  #could not parse template for following block: "template: generated:3: function \"template_dir\" not defined"
  provisioner "file" {
    destination = "/tmp/terraform-aws-vault/modules"
    source      = "${local.template_dir}/../../modules/"
  }
  provisioner "shell" {
    inline = [
      "if test -n '${var.vault_download_url}'; then",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --download-url ${var.vault_download_url};",
      "else",
      " /tmp/terraform-aws-vault/modules/install-vault/install-vault --version ${var.vault_version};",
      "fi"
      ]
  }

  #could not parse template for following block: "template: generated:3: function \"template_dir\" not defined"
  provisioner "file" {
    destination = "/tmp/sign-request.py"
    source      = "${local.template_dir}/auth/sign-request.py"
  }
  provisioner "file" {
    destination = "/tmp/ca.crt.pem"
    source      = "${var.ca_public_key_path}"
  }
  provisioner "file" {
    destination = "/tmp/vault.crt.pem"
    source      = "${var.tls_public_key_path}"
  }
  provisioner "file" {
    destination = "/tmp/vault.key.pem"
    source      = "${var.tls_private_key_path}"
  }
  provisioner "shell" {
    inline         = [
      "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
      "sudo mv /tmp/sign-request.py /opt/vault/scripts/",
      "else",
      "sudo rm /tmp/sign-request.py",
      "fi",
      "sudo mv /tmp/ca.crt.pem /opt/vault/tls/",
      "sudo mv /tmp/vault.crt.pem /opt/vault/tls/",
      "sudo mv /tmp/vault.key.pem /opt/vault/tls/",
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
    only   = ["amazon-ebs.amazon-linux-2-ami"]
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
    only   = ["amazon-ebs.ubuntu16-ami", "amazon-ebs.amazon-linux-2-ami"]
  }
  provisioner "shell" {
    inline = ["/tmp/terraform-aws-consul/modules/setup-systemd-resolved/setup-systemd-resolved"]
    only   = ["amazon-ebs.ubuntu18-ami"]
  }

  #could not parse template for following block: "template: generated:5: function \"template_dir\" not defined"
  post-processor "manifest" {
    custom_data = {
      timestamp = "Use local.timestamp when converted to hcl"
    }
    output     = "${local.template_dir}/manifest.json"
    strip_path = "true"
  }
}
