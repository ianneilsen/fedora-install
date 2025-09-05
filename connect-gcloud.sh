#!/bin/bash
# gcloud k8s cluster connect for mac/linux
# see eks script for reference

set -e

command -v gcloud >/dev/null 2>&1 || { echo "gcloud CLI required"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl required"; exit 1; }

gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1 || { echo "gcloud not authenticated"; exit 1; }

PROJECT=$(gcloud config get-value project 2>/dev/null)
[ -z "$PROJECT" ] && { echo "No GCP project set. Run: gcloud config set project PROJECT_ID"; exit 1; }

#region
ZONE=$(gcloud config get-value compute/zone 2>/dev/null || echo "")
REGION=$(gcloud config get-value compute/region 2>/dev/null || echo "")

echo "Fetching GKE clusters in project: $PROJECT"

ZONAL_CLUSTERS=""
REGIONAL_CLUSTERS=""

if [ -n "$ZONE" ]; then
    ZONAL_CLUSTERS=$(gcloud container clusters list --zone=$ZONE --format="value(name)" 2>/dev/null || echo "")
fi

if [ -n "$REGION" ]; then
    REGIONAL_CLUSTERS=$(gcloud container clusters list --region=$REGION --format="value(name)" 2>/dev/null || echo "")
fi

if [ -z "$ZONE" ] && [ -z "$REGION" ]; then
    ALL_CLUSTERS=$(gcloud container clusters list --format="value(name,zone)" 2>/dev/null || echo "")
else
    ALL_CLUSTERS=""
    if [ -n "$ZONAL_CLUSTERS" ]; then
        while read -r cluster; do
            [ -n "$cluster" ] && ALL_CLUSTERS="$ALL_CLUSTERS$cluster ($ZONE)"$'\n'
        done <<< "$ZONAL_CLUSTERS"
    fi
    if [ -n "$REGIONAL_CLUSTERS" ]; then
        while read -r cluster; do
            [ -n "$cluster" ] && ALL_CLUSTERS="$ALL_CLUSTERS$cluster ($REGION)"$'\n'
        done <<< "$REGIONAL_CLUSTERS"
    fi
fi

ALL_CLUSTERS=$(echo "$ALL_CLUSTERS" | sed '/^$/d')
[ -z "$ALL_CLUSTERS" ] && { echo "No GKE clusters found"; exit 1; }

IFS=$'\n' read -ra CLUSTER_ARRAY <<< "$ALL_CLUSTERS"

if command -v fzf >/dev/null 2>&1; then
    SELECTED=$(printf '%s\n' "${CLUSTER_ARRAY[@]}" | fzf --prompt="Select GKE cluster: " --height=10 --border --preview-window=hidden)
    [ -z "$SELECTED" ] && exit 1
else
    echo "Available clusters:"
    for i in "${!CLUSTER_ARRAY[@]}"; do
        printf "%d. %s\n" $((i+1)) "${CLUSTER_ARRAY[i]}"
    done
    
    printf "Select (1-%d): " "${#CLUSTER_ARRAY[@]}"
    read -r SELECTION
    
    if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#CLUSTER_ARRAY[@]}" ]; then
        SELECTED=${CLUSTER_ARRAY[$((SELECTION-1))]}
    else
        echo "Invalid selection"; exit 1
    fi
fi

if [[ "$SELECTED" =~ ^(.+)\ \((.+)\)$ ]]; then
    CLUSTER_NAME="${BASH_REMATCH[1]}"
    LOCATION="${BASH_REMATCH[2]}"
else
    CLUSTER_NAME=$(echo "$SELECTED" | awk '{print $1}')
    LOCATION=$(echo "$SELECTED" | awk '{print $2}')
fi

echo "Connecting to cluster: $CLUSTER_NAME in $LOCATION..."

# Determine zone or region
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$LOCATION" >/dev/null 2>&1; then
    # Zonal
    gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$LOCATION" --project="$PROJECT" >/dev/null
elif gcloud container clusters describe "$CLUSTER_NAME" --region="$LOCATION" >/dev/null 2>&1; then
    # Regional
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$LOCATION" --project="$PROJECT" >/dev/null
else
    echo "Failed to connect to cluster"
    exit 1
fi

echo "Connected! Context: $(kubectl config current-context)"
echo "kubectl get nodes"


# ~/
# ├── .config/gcloud/        # Google Cloud config
# │   ├── credentials.db     # Auth tokens
# │   ├── configurations/    # Project configs
# │   └── application_default_credentials.json
# ├── .kube/
# │   └── config            # Kubernetes configs (auto-created)
# └── scripts/
#     └── connect-gke.sh    # Your GKE script

# gcloud connect
# # Login to Google Cloud
# gcloud auth login

# # Set default project
# gcloud config set project YOUR_PROJECT_ID

# # Set default zone/region (optional but recommended)
# gcloud config set compute/zone us-central1-a
# # OR
# gcloud config set compute/region us-central1

# brew install kubectl  # Mac
# sudo apt install kubectl  # Linux

# # Mac
# brew install google-cloud-sdk

# # Linux
# curl https://sdk.cloud.google.com | bash
# exec -l $SHELL