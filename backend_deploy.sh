#!/bin/bash

# Backend deployment script for Medical Assistant app
# This script prepares and uploads backend files to the GoDaddy server

# Server details
SERVER_IP="208.109.215.53"
SERVER_USER="newgen"
BACKEND_DIR="/Users/zubairmalik/Desktop/AIAgent-Fullstack/backend"
REMOTE_DIR="~/backend"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Medical Assistant Backend Deployment =====${NC}"
echo -e "${YELLOW}This script will deploy your backend to $SERVER_USER@$SERVER_IP:$REMOTE_DIR${NC}"
echo

# Create deployment directory
echo -e "${GREEN}Creating temporary deployment directory...${NC}"
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Copy necessary files to temp directory
echo -e "${GREEN}Copying backend files...${NC}"
cp -r "$BACKEND_DIR/src" "$TEMP_DIR/"
cp -r "$BACKEND_DIR/requirements.txt" "$TEMP_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}requirements.txt not found, creating one...${NC}"
    echo "flask==2.2.3
flask-cors==3.0.10
openai==0.27.8
gunicorn==20.1.0" > "$TEMP_DIR/requirements.txt"
}

# Copy setup scripts
cp backend_setup.sh "$TEMP_DIR/"
cp medical_assistant.service "$TEMP_DIR/"

# Create WSGI file
echo -e "${GREEN}Creating app.wsgi file...${NC}"
cat > "$TEMP_DIR/app.wsgi" << EOF
import sys
import os

# Add application directory to path
sys.path.insert(0, '/home/newgen/backend')

# Set environment variables
os.environ['OPENAI_API_KEY'] = 'YOUR_OPENAI_API_KEY'

# Import Flask app
from src.erchatagent.api import app as application
EOF

# Create a simple entry point
echo -e "${GREEN}Creating app.py entry point...${NC}"
cat > "$TEMP_DIR/app.py" << EOF
from src.erchatagent.api import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

# Create directory on server
echo -e "${GREEN}Creating directory on server...${NC}"
ssh $SERVER_USER@$SERVER_IP "mkdir -p $REMOTE_DIR"

# Upload files to server
echo -e "${GREEN}Uploading files to server...${NC}"
echo -e "${YELLOW}Please enter your password when prompted${NC}"
scp -r "$TEMP_DIR/"* $SERVER_USER@$SERVER_IP:$REMOTE_DIR

# Make scripts executable
echo -e "${GREEN}Making scripts executable...${NC}"
ssh $SERVER_USER@$SERVER_IP "chmod +x $REMOTE_DIR/backend_setup.sh"

# Cleanup
echo -e "${GREEN}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

echo
echo -e "${GREEN}===== Deployment Complete =====${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. SSH to your server: ${GREEN}ssh $SERVER_USER@$SERVER_IP${NC}"
echo -e "2. Run the setup script: ${GREEN}cd $REMOTE_DIR && ./backend_setup.sh${NC}"
echo -e "3. Edit app.wsgi to set your OpenAI API key: ${GREEN}nano $REMOTE_DIR/app.wsgi${NC}"
echo -e "4. Set up the systemd service: ${GREEN}sudo cp $REMOTE_DIR/medical_assistant.service /etc/systemd/system/${NC}"
echo -e "5. Start the service: ${GREEN}sudo systemctl enable medical_assistant && sudo systemctl start medical_assistant${NC}"
echo -e "6. Check service status: ${GREEN}sudo systemctl status medical_assistant${NC}" 