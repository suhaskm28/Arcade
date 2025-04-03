#!/bin/bash

# Define color variables
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

# Welcome message
clear
echo "${BLUE}${BOLD}Initializing Execution...${RESET}"

# User input
read -p "${YELLOW}${BOLD}Enter API Key: ${RESET}" API_KEY
read -p "${YELLOW}${BOLD}Enter Task 2 output file name: ${RESET}" task_2_file
read -p "${YELLOW}${BOLD}Enter Task 3 request file name: ${RESET}" task_3_request
read -p "${YELLOW}${BOLD}Enter Task 3 response file name: ${RESET}" task_3_response
read -p "${YELLOW}${BOLD}Enter sentence to translate (Task 4): ${RESET}" task_4_text
read -p "${YELLOW}${BOLD}Enter Task 4 output file name: ${RESET}" task_4_file
read -p "${YELLOW}${BOLD}Enter sentence for language detection (Task 5): ${RESET}" task_5_text
read -p "${YELLOW}${BOLD}Enter Task 5 output file name: ${RESET}" task_5_file

audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"
PROJECT_ID=$(gcloud config get-value project)
source venv/bin/activate

# Text-to-Speech request
cat > synthesize-text.json <<EOF
{
  "input": {"text": "Cloud Text-to-Speech API allows developers to include natural-sounding speech in their applications."},
  "voice": {"languageCode": "en-gb", "name": "en-GB-Standard-A", "ssmlGender": "FEMALE"},
  "audioConfig": {"audioEncoding": "MP3"}
}
EOF

curl -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
     -H "Content-Type: application/json" \
     -d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" > "$task_2_file"

# Speech-to-Text request
cat > "$task_3_request" <<EOF
{
  "config": {"encoding": "FLAC", "sampleRateHertz": 44100, "languageCode": "fr-FR"},
  "audio": {"uri": "$audio_uri"}
}
EOF

curl -s -X POST -H "Content-Type: application/json" \
     --data-binary @"$task_3_request" \
     "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" -o "$task_3_response"

# Translation request
curl -s -X POST -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
     -H "Content-Type: application/json" \
     -d "{\"q\": \"$task_4_text\"}" \
     "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en" > "$task_4_file"

# Language detection request
curl -s -X POST -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
     -H "Content-Type: application/json" \
     -d "{\"q\": [\"$task_5_text\"]}" \
     "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" -o "$task_5_file"

echo "${GREEN}${BOLD}Lab Completed Successfully!${RESET}"
