#!/bin/bash

aws s3 sync s3://ec2-linux-nvidia-drivers/latest/ /tmp/.
export PKR_VAR_nvidia_driver=$(ls /tmp/NVIDIA-Linux-x86_64-*-grid-aws.run | tail -1)
packer build nice-dcv.json.pkr.hcl 