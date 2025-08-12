# Deployment Guide for Medical Assistant App

This guide will help you deploy both the backend and the Flutter app to your GoDaddy server.

## Server Information

- Server IP: 208.109.215.53
- User: newgen
- Ubuntu 22.04

## Backend Deployment

1. **SSH to your server**:
   ```bash
   ssh newgen@208.109.215.53
   ```
   Enter your password when prompted.

2. **Create a directory for the backend**:
   ```bash
   mkdir -p ~/backend
   ```

3. **Upload the backend files**:
   You can use SFTP, SCP, or any file transfer tool to upload the backend code to the `~/backend` directory.
   
   Example using SCP from your local machine:
   ```bash
   scp -r /path/to/local/backend/* newgen@208.109.215.53:~/backend/
   ```

4. **Run the setup script**:
   ```bash
   cd ~/backend
   chmod +x backend_setup.sh
   ./backend_setup.sh
   ```

5. **Update OpenAI API key**:
   Edit the `app.wsgi` file and replace 'YOUR_OPENAI_API_KEY' with your actual OpenAI API key:
   ```bash
   nano app.wsgi
   ```

6. **Configure the service**:
   ```bash
   # Copy the service file to systemd
   sudo cp medical_assistant.service /etc/systemd/system/

   # Edit the service file to update your API key
   sudo nano /etc/systemd/system/medical_assistant.service
   
   # Enable and start the service
   sudo systemctl daemon-reload
   sudo systemctl enable medical_assistant
   sudo systemctl start medical_assistant
   
   # Check service status
   sudo systemctl status medical_assistant
   ```

7. **Open firewall port**:
   ```bash
   sudo ufw allow 5001
   ```

## Flutter App Deployment

### Option 1: Build and Upload Flutter Web

1. **Build the Flutter web app**:
   ```bash
   cd /path/to/flutter_app
   flutter build web --release
   ```

2. **Upload the web build to the server**:
   ```bash
   scp -r build/web/* newgen@208.109.215.53:~/public_html/
   ```

### Option 2: Build APK for Android

1. **Build the APK**:
   ```bash
   cd /path/to/flutter_app
   flutter build apk --release
   ```

2. **The APK will be located at**:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
   
   You can download this file and install it on Android devices.

## Testing the Deployment

1. **Test backend API**:
   ```bash
   curl http://208.109.215.53:5001/
   ```
   You should see a response like: `{"status":"API is running", "endpoints":["/api/chat"]}`

2. **Test API with a message**:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"message":"Hello", "session_id":"test123"}' http://208.109.215.53:5001/api/chat
   ```

## Troubleshooting

1. **Check service logs if there are issues**:
   ```bash
   sudo journalctl -u medical_assistant -f
   ```

2. **Restart the service if needed**:
   ```bash
   sudo systemctl restart medical_assistant
   ```

3. **Check backend is running**:
   ```bash
   ps aux | grep python
   ```

4. **Ensure the firewall is configured correctly**:
   ```bash
   sudo ufw status
   ```

## Maintenance

1. **To update the backend**:
   ```bash
   cd ~/backend
   # Upload new files, then
   sudo systemctl restart medical_assistant
   ```

2. **To update the Flutter app**:
   Rebuild the app with updated configuration and replace the files on the server. 