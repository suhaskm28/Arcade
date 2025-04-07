#!/bin/bash

# Define color variables
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)
BG_MAGENTA=$(tput setab 5)
BG_RED=$(tput setab 1)

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export REGION="${ZONE%-*}"

# Create jumphost instance
gcloud compute instances create "$INSTANCE" \
    --zone="$ZONE" \
    --machine-type=e2-micro

echo "${RED}${BOLD}Task 1.${RESET} ${WHITE}${BOLD}Create a project jumphost instance${RESET} ${GREEN}${BOLD}Completed${RESET}"

# Create startup script
cat << EOF > startup.sh
#!/bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i 's/nginx/Google Cloud Platform - \$HOSTNAME/' /var/www/html/index.nginx-debian.html
EOF

# Create instance template
gcloud compute instance-templates create web-server-template \
    --metadata-from-file startup-script=startup.sh \
    --machine-type=e2-medium \
    --region="$REGION"

# Create managed instance group
gcloud compute instance-groups managed create web-server-group \
    --base-instance-name=web-server \
    --size=2 \
    --template=web-server-template \
    --region="$REGION"

# Create firewall rule
gcloud compute firewall-rules create "$FIREWALL" \
    --allow tcp:80 \
    --network=default

# Set up load balancer components
gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed set-named-ports web-server-group \
    --named-ports http:80 \
    --region="$REGION"

gcloud compute backend-services create web-server-backend \
    --protocol=HTTP \
    --http-health-checks=http-basic-check \
    --global

gcloud compute backend-services add-backend web-server-backend \
    --instance-group=web-server-group \
    --instance-group-region="$REGION" \
    --global

gcloud compute url-maps create web-server-map \
    --default-service=web-server-backend

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map=web-server-map

gcloud compute forwarding-rules create http-content-rule \
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80

gcloud compute forwarding-rules list

echo "${RED}${BOLD}Task 2.${RESET} ${WHITE}${BOLD}Set up an HTTP load balancer${RESET} ${GREEN}${BOLD}Completed${RESET}"

echo "${YELLOW}${BOLD}Note:${RESET} ${CYAN}${BOLD}It may take ${RED}5 to 7 minutes${CYAN} for the score to reflect.${RESET}"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
