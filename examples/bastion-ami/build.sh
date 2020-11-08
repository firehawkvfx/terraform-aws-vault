#!/bin/bash

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

# Packer Vars
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
export PACKER_LOG=1
export PACKER_LOG_PATH="packerlog.log"

rm -f manifest.json
packer build bastion.json.pkr.hcl 