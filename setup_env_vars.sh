#!/bin/bash

# Script to set up environment variables in systemd service

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Setting up environment variables =====${NC}"

# Change to backend directory
cd ~/backend

# Create a backup of the current service file
sudo cp /etc/systemd/system/medical_assistant.service /etc/systemd/system/medical_assistant.service.bak

# Read API key from current .env file if it exists
API_KEY=""
if [ -f ".env" ]; then
  API_KEY=$(grep "OPENAI_API_KEY" .env | cut -d '=' -f2)
  echo -e "${YELLOW}Found API key in .env file${NC}"
else
  echo -e "${YELLOW}No .env file found. Please enter your OpenAI API key:${NC}"
  read -p "API key: " API_KEY
fi

# Create updated service file with environment variables
cat > medical_assistant.service << EOF
[Unit]
Description=Medical Assistant API Service
After=network.target

[Service]
User=newgen
Group=newgen
WorkingDirectory=/home/newgen/backend
ExecStart=/home/newgen/backend/venv/bin/python3 /home/newgen/backend/app.py

# Environment variables
Environment="OPENAI_API_KEY=$API_KEY"
Environment="FLASK_APP=app.py"
Environment="FLASK_DEBUG=False"
Environment="PORT=5001"
Environment="SERVER_HOST=0.0.0.0"
Environment="LOG_LEVEL=INFO"

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Copy updated service file and reload
sudo cp medical_assistant.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart medical_assistant

# Check service status
echo -e "${GREEN}Service updated with environment variables${NC}"
sudo systemctl status medical_assistant

echo -e "${GREEN}===== Setup Complete =====${NC}"
echo -e "${YELLOW}You can now safely remove the .env file${NC}"
echo -e "${YELLOW}To remove it, run: rm .env${NC}" 