#!/usr/bin/env python3
from flask import Flask, request, jsonify
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

@app.route("/", methods=["GET"])
def root():
    """Root endpoint"""
    return jsonify({"status": "API is running", "endpoints": ["/api/chat", "/health"]}), 200

@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "message": "Medical Assistant API is running"}), 200

@app.route("/api/chat", methods=["POST"])
def chat():
    """Main chat endpoint for medical assistant"""
    try:
        data = request.json
        if not data or "message" not in data:
            return jsonify({"error": "Invalid request. 'message' field is required"}), 400

        user_message = data.get("message")
        session_id = data.get("session_id", "unknown")
        
        # Simple echo response for testing
        response = {
            "response": f"Echo: {user_message}",
            "session_id": session_id
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=False) 