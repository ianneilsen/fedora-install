#!/bin/bash

# Mac/Linux)
set -e

# fail if tools missing
command -v aws >/dev/null 2>&1 || { echo "AWS CLI required"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl required"; exit 1; }

aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS not configured"; exit 1; }

REGION=${AWS_DEFAULT_REGION:-$(aws configure get region || echo "us-east-1")}

echo "Fetching EKS clusters in $REGION..."

CLUSTERS=$(aws eks list-clusters --region $REGION --output text --query 'clusters[*]' 2>/dev/null)

[ -z "$CLUSTERS" ] && { echo "No clusters found"; exit 1; }

IFS=$' \t\n' read -ra CLUSTER_ARRAY <<< "$CLUSTERS"

echo "Available clusters:"
for i in "${!CLUSTER_ARRAY[@]}"; do
    printf "%d. %s\n" $((i+1)) "${CLUSTER_ARRAY[i]}"
done

printf "Select (1-%d): " "${#CLUSTER_ARRAY[@]}"
read -r SELECTION

#validate
if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#CLUSTER_ARRAY[@]}" ]; then
    CLUSTER=${CLUSTER_ARRAY[$((SELECTION-1))]}
    echo "🔗 Connecting to $CLUSTER..."
    
    aws eks update-kubeconfig --region $REGION --name $CLUSTER >/dev/null
    
    echo "Connected! Context: $(kubectl config current-context)"
    echo "kubectl get namespaces"
else
    echo "Invalid selection"
    exit 1
fi