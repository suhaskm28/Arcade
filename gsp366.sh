#!/bin/bash

# gsp366.sh - Automated setup and inference for defect detection

# Step 1: Name the artifact for clarity
export product_inspection=gcr.io/ql-shared-resources-test/defect_solution@sha256:776fd8c65304ac017f5b9a986a1b8189695b7abbff6aa0e4ef693c46c7122f4c

# Step 2: Set Docker tag using named variable
export DOCKER_TAG=${product_inspection}

# Step 3: Export required variables
export VISERVING_CPU_DOCKER_WITH_MODEL=${DOCKER_TAG}
export HTTP_PORT=8602
export LOCAL_METRIC_PORT=8603

# Step 4: Pull Docker image
docker pull ${VISERVING_CPU_DOCKER_WITH_MODEL}

# Step 5: Run Docker container as "product_inspection"
docker run -v /secrets:/secrets --rm -d --name "product_inspection" \
  --network="host" \
  -p ${HTTP_PORT}:8602 \
  -p ${LOCAL_METRIC_PORT}:8603 \
  -t ${VISERVING_CPU_DOCKER_WITH_MODEL} \
  --metric_project_id="${PROJECT_ID}" \
  --use_default_credentials=false \
  --service_account_credentials_json=/secrets/assembly-usage-reporter.json

# Step 6: Check Docker container is running
docker container ls

# Step 7: Download prediction script
gsutil cp gs://cloud-training/gsp895/prediction_script.py .

# Step 8: Copy test images
export PROJECT_ID=$(gcloud config get-value core/project)
gsutil mb -p ${PROJECT_ID} gs://${PROJECT_ID}
gsutil -m cp gs://cloud-training/gsp897/cosmetic-test-data/*.png gs://${PROJECT_ID}/cosmetic-test-data/
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_07703.png .
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_0769.png .

# Step 9: Python environment setup
sudo apt update
sudo apt install python3 -y
sudo apt install python3-pip -y
sudo apt install python3.11-venv -y 
python3 -m venv create myvenv
source myvenv/bin/activate
pip install absl-py  
pip install numpy 
pip install requests

# Step 10: Run prediction for defective product
python3 ./prediction_script.py \
  --input_image_file=./IMG_07703.png \
  --port=8602 \
  --output_result_file=defective_product.json

# Step 11: Run prediction for non-defective product
python3 ./prediction_script.py \
  --input_image_file=./IMG_0769.png \
  --port=8602 \
  --output_result_file=non_defective_product_result.json

# Step 12: Run 10 predictions for latency test
python3 ./prediction_script.py \
  --input_image_file=./IMG_0769.png \
  --port=8602 \
  --num_of_requests=10 \
  --output_result_file=non_def_latency_result.json

echo "All steps completed successfully."
