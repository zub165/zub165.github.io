#!/bin/bash

# Backend setup script for Medical Assistant app
# This script sets up the Python environment and installs dependencies on the server

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

BACKEND_DIR="/home/newgen/backend"

echo -e "${GREEN}===== Medical Assistant Backend Setup =====${NC}"
echo -e "${YELLOW}This script will set up the backend environment in $BACKEND_DIR${NC}"
echo

# Update package lists
echo -e "${GREEN}Updating package lists...${NC}"
sudo apt-get update

# Install Python and pip if not already installed
echo -e "${GREEN}Installing Python and dependencies...${NC}"
sudo apt-get install -y python3 python3-pip python3-venv

# Create virtual environment
echo -e "${GREEN}Creating Python virtual environment...${NC}"
cd $BACKEND_DIR
python3 -m venv venv

# Activate virtual environment and install dependencies
echo -e "${GREEN}Installing Python packages...${NC}"
source venv/bin/activate
pip install -r requirements.txt

# Create logs directory
echo -e "${GREEN}Creating logs directory...${NC}"
mkdir -p logs

# Update service file
echo -e "${GREEN}Updating service file...${NC}"
sed -i "s|/path/to/backend|$BACKEND_DIR|g" medical_assistant.service

echo
echo -e "${GREEN}===== Backend Setup Complete =====${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Edit app.wsgi to set your OpenAI API key: ${GREEN}nano $BACKEND_DIR/app.wsgi${NC}"
echo -e "2. Set up the systemd service: ${GREEN}sudo cp $BACKEND_DIR/medical_assistant.service /etc/systemd/system/${NC}"
echo -e "3. Start the service: ${GREEN}sudo systemctl enable medical_assistant && sudo systemctl start medical_assistant${NC}"
echo -e "4. Open firewall port: ${GREEN}sudo ufw allow 5001${NC}"
echo -e "5. Check service status: ${GREEN}sudo systemctl status medical_assistant${NC}" 