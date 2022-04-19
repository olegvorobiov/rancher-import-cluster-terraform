#!/bin/bash

CLUSTER_NAME="imported-lab-1"
BEARER_TOKEN="token-blabla:blablablablablablablablablablablablablablablabla"
CLUSTER_URL="https://yourdomain.com"





# Get cluster id based on a cluster name
CLUSTER_ID=$(curl -k -s "$CLUSTER_URL/v3/clusters" -H "Authorization: Bearer $BEARER_TOKEN" | jq -r '.data[] | select(.name == '\"$CLUSTER_NAME\"') | .id')

# Delete cluster from Rancher, redirect to dev null needed since it generates tons of output
curl -k -s -X DELETE "$CLUSTER_URL/v3/clusters/$CLUSTER_ID" -H "Authorization: Bearer $BEARER_TOKEN" > /dev/null