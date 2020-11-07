#!/bin/bash

aws s3 sync s3://ec2-linux-nvidia-drivers/latest/ .
export PKR_VAR_nvidia_driver=$(ls NVIDIA-Linux-x86_64-*-grid-aws.run | tail -1)
packer build nice-dcv.json.pkr.hcl 