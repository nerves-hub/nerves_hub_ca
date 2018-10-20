#!/bin/bash

set -e

export AWS_ENV_PATH="/nerves_hub_ca/$ENVIRONMENT/"

# Set env vars from AWS SSM
# This uses get-parameters-from-path and automatically sets any that match the prefix above (AWS_ENV_PATH)
# http://docs.aws.amazon.com/cli/latest/reference/ssm/get-parameters-by-path.html
eval $(aws-env)

WORKING_DIR=${WORKING_DIR:-/etc/ssl}
S3_BUCKET=${S3_BUCKET:-'nerves-hub-ca'}

mkdir -p $WORKING_DIR
aws s3 sync s3://$S3_BUCKET/ssl $WORKING_DIR

exec $@
