#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome Message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...       ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Step 1: Set default zone
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} Setting compute zone."
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Create GKE cluster
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} Creating GKE cluster 'gmp-cluster' with 3 nodes."
gcloud container clusters create gmp-cluster --num-nodes=3 --zone=$ZONE

# Step 3: Get cluster credentials
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} Fetching cluster credentials."
gcloud container clusters get-credentials gmp-cluster --zone=$ZONE

# Step 4: Create namespace
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} Creating namespace 'gmp-test'."
kubectl create ns gmp-test

# Step 5: Apply Prometheus setup
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} Applying Prometheus manifests."
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/manifests/setup.yaml
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/manifests/operator.yaml
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.2.3/examples/example-app.yaml

# Step 6: Create OperatorConfig file
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} Creating OperatorConfig file 'op-config.yaml'."
cat > op-config.yaml <<'EOF'
apiVersion: monitoring.googleapis.com/v1alpha1
kind: OperatorConfig
metadata:
  name: config
  namespace: gmp-public
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
  annotations:
    components.gke.io/layer: addon
collection:
  filter:
    matchOneOf:
      - '{job="prom-example"}'
      - '{__name__=~"job:.+"}'
EOF

# Step 7: Create GCS bucket
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} Creating a GCS bucket."
export PROJECT=$(gcloud config get-value project)
gsutil mb -p $PROJECT gs://$PROJECT

# Step 8: Upload config to bucket
echo "${CYAN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} Uploading 'op-config.yaml' to the bucket."
gsutil cp op-config.yaml gs://$PROJECT

# Step 9: Make the bucket publicly readable
echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} Setting public-read access on the bucket."
gsutil -m acl set -R -a public-read gs://$PROJECT

# Done!
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}***********************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}         LAB COMPLETED!            ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}***********************************${RESET_FORMAT}"
