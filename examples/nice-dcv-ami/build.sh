#!/bin/bash

# Take the base AMI created from the bastion-ami folder and install NVIDIA drivers.

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

# Packer Vars
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
if [[ -f "../bastion-ami/manifest.json" ]]; then
    export PKR_VAR_bastion_centos7_ami="$(jq -r '.builds[] | select(.name == "centos7-ami") | .artifact_id' ../bastion-ami/manifest.json | tail -1 | cut -d ":" -f2)"
    echo "Found bastion_centos7_ami in manifest: PKR_VAR_bastion_centos7_ami=$PKR_VAR_bastion_centos7_ami"
fi
export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"

mkdir -p /tmp/nvidia/
aws s3 sync s3://ec2-linux-nvidia-drivers/latest/ /tmp/nvidia/. --include "NVIDIA-Linux-x86_64-*-grid-aws.run"
export PKR_VAR_nvidia_driver=$(ls /tmp/nvidia/NVIDIA-Linux-x86_64-*-grid-aws.run | tail -1)

rm -f manifest.json
packer build nice-dcv.json.pkr.hcl 