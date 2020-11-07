#!/bin/bash

mkdir -p /tmp/nvidia/
aws s3 sync s3://ec2-linux-nvidia-drivers/latest/ /tmp/nvidia/. --include "NVIDIA-Linux-x86_64-*-grid-aws.run"
export PKR_VAR_nvidia_driver=$(ls /tmp/nvidia/NVIDIA-Linux-x86_64-*-grid-aws.run | tail -1)
packer build nice-dcv.json.pkr.hcl 