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
  default = null
}

variable "ca_public_key_path" {
  type    = string
  default = "/home/ec2-user/.ssh/tls/ca.crt.pem"
}

variable "install_auth_signing_script" {
  type    = string
  default = "true"
}

variable "bastion_centos7_ami" {
  type    = string
  default = null
}

variable "nvidia_driver" { # run aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ . # to pull latest nvidia driver, then provide the file name as this var
  type = string
  default = null
}

locals {
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  template_dir = path.root
}

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/from-1.5/blocks/source
#could not parse template for following block: "template: generated:4: function \"clean_resource_name\" not defined"

# source "amazon-ebs" "amazon-linux-2-ami" {
#   ami_description = "An Amazon Linux 2 AMI that will accept connections from hosts with TLS Certs."
#   ami_name        = "firehawk-base-amazon-linux-2-{{isotime | clean_resource_name}}-{{uuid}}"
#   instance_type   = "t2.micro"
#   region          = "{{user `aws_region`}}"
#   source_ami_filter {
#     filters = {
#       architecture                       = "x86_64"
#       "block-device-mapping.volume-type" = "gp2"
#       name                               = "*amzn2-ami-hvm-*"
#       root-device-type                   = "ebs"
#       virtualization-type                = "hvm"
#     }
#     most_recent = true
#     owners      = ["amazon"]
#   }
#   ssh_username = "ec2-user"
# }

#could not parse template for following block: "template: generated:4: function \"clean_resource_name\" not defined"

source "amazon-ebs" "centos7-nicedcv-nvidia-ami" {
  ami_description = "A Remote Workstation NICE DCV NVIDIA Cent OS 7 AMI that will accept connections from hosts with TLS Certs."
  ami_name        = "firehawk-base-centos7-nicedcv-nvidia-ami-${local.timestamp}-{{uuid}}"
  instance_type   = "g3s.xlarge"
  region          = "${var.aws_region}"
  source_ami      = "${var.bastion_centos7_ami}"
  ssh_username    = "centos"
  # assume_role { # Since we need to read files from s3, we require a role with read access.
  #     role_arn     = "arn:aws:iam::972620357255:role/S3-Admin-S3" # This needs to be replaced with a terraform output
  #     session_name = "SESSION_NAME"
  #     external_id  = "EXTERNAL_ID"
  # }
}

#could not parse template for following block: "template: generated:4: function \"clean_resource_name\" not defined"


# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/from-1.5/blocks/build
build {
  sources = ["source.amazon-ebs.centos7-nicedcv-nvidia-ami"]

  provisioner "shell" {
    inline = [
      "mkdir -p /tmp/terraform-aws-vault/modules",
      "mkdir -p /tmp/nvidia"
      ]
  }

  #could not parse template for following block: "template: generated:3: function \"template_dir\" not defined"
  provisioner "file" {
    destination = "/tmp/terraform-aws-vault/modules"
    source      = "${local.template_dir}/../../modules/"
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

  # These shell provisioners are commented out since all these steps should be done in the base image because yum update takes a long time

  # provisioner "shell" {
  #   inline         = [
  #     "if [[ '${var.install_auth_signing_script}' == 'true' ]]; then",
  #     "sudo mkdir -p /opt/vault/scripts/",
  #     "sudo mv /tmp/sign-request.py /opt/vault/scripts/",
  #     "else",
  #     "sudo rm /tmp/sign-request.py",
  #     "fi",
  #     "sudo mkdir -p /opt/vault/tls/",
  #     "sudo mv /tmp/ca.crt.pem /opt/vault/tls/",
  #     "echo 'TrustedUserCAKeys /opt/vault/tls/ca.crt.pem' | sudo tee -a /etc/ssh/sshd_config",
  #     "echo \"@cert-authority * $(sudo cat /opt/vault/tls/ca.crt.pem)\" | sudo tee -a /etc/ssh/ssh_known_hosts",
  #     "sudo chmod -R 600 /opt/vault/tls",
  #     "sudo chmod 700 /opt/vault/tls",
  #     "sudo /tmp/terraform-aws-vault/modules/update-certificate-store/update-certificate-store --cert-file-path /opt/vault/tls/ca.crt.pem"
  #     ]
  #   inline_shebang = "/bin/bash -e"
  # }
  # provisioner "shell" {
  #   inline = [
  #     "sudo yum update -y",
  #     "sleep 5",
  #     "sudo yum install -y git",
  #     "sudo yum install -y python python3.7 python3-pip",
  #     "python3 -m pip install --user --upgrade pip",
  #     "python3 -m pip install --user boto3"
  #     ]

  # }
  # provisioner "shell" {
  #   inline = [
  #     "sudo yum groupinstall -y \"GNOME Desktop\" \"Development Tools\"",
  #     "sudo yum -y install kernel-devel",
  #     "sudo yum -y install epel-release",
  #     "sudo yum -y install dkms",
  #     "sudo yum upgrade -y",
  #     "mkdir -p /tmp/nvidia/" # ensure dir exists
  #     ]
  # }
  # provisioner "shell" {
  #   expect_disconnect = true
  #   inline            = ["sudo reboot"]
  # }

  provisioner "file" {
    destination = "${var.nvidia_driver}"
    source      = "${var.nvidia_driver}"
  }

  provisioner "shell" {
    inline = [
      "sudo yum install -y gcc kernel-devel-$(uname -r)",
      <<EOFO
cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau nouveau.modeset=0"' | sudo tee --append /etc/default/grub
sudo cat /etc/default/grub
EOFO
      ,
      "sudo grub2-mkconfig -o /boot/grub2/grub.cfg",
      "sudo mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img", # backup old initramfs
      "sudo dracut -fv /boot/initramfs-$(uname -r).img $(uname -r)",
      "sleep 5"
      ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }
  provisioner "shell" {
    inline = [
      "set -x; ls -ltriah /tmp/nvidia/; sudo chmod +x ${var.nvidia_driver}",
      "ls -ltriah /tmp/nvidia/", # Check exec permissions
      "sudo systemctl get-default", # should be multi-user.target # "sleep 5; sudo systemctl isolate multi-user.target",
      "cd /tmp/nvidia; set -o pipefail; sudo /bin/bash ${var.nvidia_driver} -x -s -j 1 || cat /var/log/nvidia-installer.log; ls -ltriah", #extract
      "folder=$(echo ${var.nvidia_driver} | cut -d '.' -f-3)",
      "ls -ltriah /tmp/nvidia/; ls -ltriah $folder/",
      "sudo $folder/nvidia-installer --dkms -s --install-libglvnd -j 1 || cat /var/log/nvidia-installer.log",
      "echo 'Installed Nvidia Driver'"
      # "sudo dracut -fv" # Not entirely sure this is necesary.
      ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }
  provisioner "shell" {
    inline = [
      "set -x",
      "nvidia-smi -q | head", # Confirm the driver is working.
      "sudo systemctl get-default",
      # "sudo yum groupinstall -y \"Graphical Administration Tools\"",
      "sudo systemctl enable graphical.target",
      # "sudo systemctl start graphical.target || sudo systemctl status graphical.target",
      "sleep 5; sudo systemctl set-default graphical.target"
    ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }

# This point could be snapshotted for a gpu instance to render.  Instead we continue to enable a graphical ui.

# we seem to need to reboot because we produce these errors otherwise.
# ==> amazon-ebs.centos7-nicedcv-nvidia-ami: + sudo systemctl isolate graphical.target
# ==> amazon-ebs.centos7-nicedcv-nvidia-ami: Failed to start graphical.target: Transaction is destructive.

  provisioner "shell" {
    inline = [
      "set -x; sudo systemctl get-default; sleep 5",
      # "set -o pipefail; sudo systemctl isolate graphical.target || systemctl status graphical.target",
      "ps aux | grep X | grep -v grep",
      "sudo yum install -y glx-utils", # Install the glxinfo Utility
      # "sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep \"X.*\\-auth\" | grep -v grep | sed -n 's/.*-auth \\([^ ]\\+\\).*/\\1/p') glxinfo | grep -i \"opengl.*version\"", # Verify OpenGL Software Rendering
      "sudo nvidia-xconfig --preserve-busid --enable-all-gpus",
      "sudo ls -ltriah /etc/X11",
      # "nvidia-xconfig --preserve-busid --enable-all-gpus --connected-monitor=DFP-0,DFP-1,DFP-2,DFP-3", # multimonitor config
      # "sudo rm -rf /etc/X11/XF86Config*"
    ]
  }
  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo reboot"]
  }
  provisioner "shell" {
    inline = [
      "set -x",
      "sudo systemctl get-default",
      "sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep \"X.*\\-auth\" | grep -v grep | sed -n 's/.*-auth \\([^ ]\\+\\).*/\\1/p') glxinfo | grep -i \"opengl.*version\"",
      "sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY",
      "wget https://d1uj6qtbmh3dt5.cloudfront.net/2020.1/Servers/nice-dcv-2020.1-9012-el7-x86_64.tgz",
      "tar -xvzf nice-dcv-2020.1-9012-el7-x86_64.tgz",
      "cd nice-dcv-2020.1-9012-el7-x86_64",
      "ls -ltriah",
      "sudo yum install -y nice-dcv-server-2020.1.9012-1.el7.x86_64.rpm",
      "sudo yum install -y nice-xdcv-2020.1.338-1.el7.x86_64.rpm",
      "# gpu sharing disabled but can be enabled for workstations # sudo yum install -y nice-dcv-gl-2020.1.840-1.el7.x86_64.rpm",
      "# usb devices disabled # sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm; sudo yum install dkms; sudo dcvusbdriverinstaller"
      ]
  }
  post-processor "manifest" {
      output = "manifest.json"
      strip_path = true
      custom_data = {
        timestamp = "${local.timestamp}"
      }
  }
}
