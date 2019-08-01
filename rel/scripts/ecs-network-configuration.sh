#!/bin/bash

set -e

VPC=$1
SG=$2

VPCS=$(aws ec2 describe-vpcs --output json | jq ".Vpcs")
VPC=$(echo $VPCS | jq --arg VPC $VPC '.[] | . as $vpc | .Tags[] | select(.Key == "Name" and .Value == $VPC) | $vpc.VpcId')

SUBNETS=$(aws ec2 describe-subnets --filters=Name=vpc-id,Values=$VPC,Name=tag:Name,Values=*private* --output json | jq -c '[.Subnets[] | .SubnetId]')
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters=Name=tag:Name,Values=$SG | jq -c '[.SecurityGroups[] | .GroupId ]')

echo "awsvpcConfiguration={subnets=$SUBNETS,securityGroups=$SECURITY_GROUPS,assignPublicIp=DISABLED}"
