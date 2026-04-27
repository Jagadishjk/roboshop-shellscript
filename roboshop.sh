#!/bin/bash

SG_ID="sg-07609b6e775dec527"
AMI_ID="ami-0220d79f3f480ecf5"
HOSTED_ZONE_ID="Z0155771HQMTGJEVZQWS"
INSTANCE_TYPE="t3.micro"
DOMAIN_NAME="techlineruns.online"


for instance in "$@"; do
    echo "[INFO]: Creating $instance instance..."
    INSATNCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' \
    --output text)

    echo "[INFO]: Created $instance instance successfully."
        if [ $instance == "frontend" ]; then
            echo "[INFO]: Fetching Public IP for $instance."
            IP=$(aws ec2 describe-instances \
            --instance-ids $INSATNCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
            RECORD_NAME="$DOMAIN_NAME" # For frontend, we want the record to be techlineruns.online instead of frontend.techlineruns.online
        else
            echo "[INFO]: Fetching Private IP for $instance."
            IP=$(aws ec2 describe-instances \
            --instance-ids $INSATNCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
            RECORD_NAME="$instance.$DOMAIN_NAME" # For other instances, we want the record to be instance.techlineruns.online
        fi
    echo "[INFO]: Fetched IP $IP for $instance instance successfully."

    echo "[INFO]: Creating DNS record for $instance."
    aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '
    echo "[INFO]: Created DNS record for $instance successfully."
done
