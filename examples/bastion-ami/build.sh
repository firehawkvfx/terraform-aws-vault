#!/bin/bash

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

# Packer Vars
export PKR_VAR_aws_region="$AWS_DEFAULT_REGION"
export PACKER_LOG=1
export PACKER_LOG_PATH="$SCRIPTDIR/packerlog.log"

export PKR_VAR_manifest_path="$SCRIPTDIR/manifest.json"
rm -f $PKR_VAR_manifest_path
packer build $SCRIPTDIR/bastion.json.pkr.hcl | python -c 'import sys,time;sys.stdout.write("".join(( " ".join((time.strftime("[%Y-%m-%d %H:%M:%S]", time.localtime()), line)) for line in sys.stdin )))'