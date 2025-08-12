#!/usr/bin/env python3
from flask import Flask, request, jsonify
import os
import sys
import argparse
from dotenv import load_dotenv
import openai
from openai import OpenAI
import logging
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Parse command line arguments
parser = argparse.ArgumentParser(description='Medical Assistant API')
parser.add_argument('--port', type=int, default=5001, help='Port to run the server on')
args = parser.parse_args()

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure OpenAI API key
openai_api_key = os.getenv("OPENAI_API_KEY")
if not openai_api_key:
    logger.error("OPENAI_API_KEY not set in environment variables")
    raise ValueError("OPENAI_API_KEY is required")

# Initialize OpenAI client
client = OpenAI(api_key=openai_api_key)

# In-memory storage for conversations (in production, use a database)
conversations = {}

# Medical response template
MEDICAL_TEMPLATE = """
Assessment:
{assessment}

Differential Diagnosis (in order of clinical concern):
{diagnosis}

Recommended Actions:
{treatment}

IMPORTANT DISCLAIMER: 
{disclaimer}
"""

# Emergency disclaimer
EMERGENCY_DISCLAIMER = "This is not medical advice. If you're experiencing a medical emergency, call 911 or your local emergency number immediately. This information is for educational purposes only."

# Standard questions to gather patient information
STANDARD_QUESTIONS = [
    "1. How long have you been experiencing these symptoms?",
    "2. Where exactly is the pain/discomfort located?",
    "3. Does the pain/discomfort radiate to other areas?",
    "4. How would you rate the severity on a scale of 1-10?",
    "5. Are there any activities or positions that make it better or worse?",
    "6. Have you taken any medications for this?",
    "7. Do you have any relevant medical history or conditions?"
]

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
        language = data.get("language", "en")
        
        # Get conversation history
        if session_id not in conversations:
            conversations[session_id] = []
        
        # Add user message to history
        conversations[session_id].append({"role": "user", "content": user_message})
        
        # Prepare messages for OpenAI
        messages = [
            {"role": "system", "content": """You are a medical assistant helping patients understand their symptoms. You MUST ALWAYS follow this EXACT format for EVERY response:

If this is the patient's first message or if you don't have enough information, ONLY ask these seven questions and nothing else:

1. How long have you been experiencing these symptoms?
2. Where exactly is the pain/discomfort located?
3. Does the pain/discomfort radiate to other areas?
4. How would you rate the severity on a scale of 1-10?
5. Are there any activities or positions that make it better or worse?
6. Have you taken any medications for this?
7. Do you have any relevant medical history or conditions?

Once you have sufficient information, ALWAYS structure your response EXACTLY like this:

DIFFERENTIAL DIAGNOSIS:
1. [Most likely serious condition]
2. [Second most likely condition]
3. [Third most likely condition]
4. [Other possible conditions]

PATIENT SUMMARY:
- Duration: [How long symptoms have been present]
- Location: [Where symptoms are located]
- Severity: [Pain/discomfort level]
- Aggravating/Relieving Factors: [What makes it better/worse]
- Current Medications: [What patient has tried]
- Relevant History: [Important medical history]

TREATMENT RECOMMENDATIONS:
1. [Most urgent action needed]
2. [Second most important action]
3. [Additional recommendations]
4. [Lifestyle modifications]
5. [Follow-up recommendations]

EMERGENCY WARNING SIGNS:
Seek immediate emergency care if you experience any of these:
- [Specific warning sign 1]
- [Specific warning sign 2]
- [Specific warning sign 3]

IMPORTANT DISCLAIMER:
This is not medical advice. If you're experiencing a medical emergency, call 911 or your local emergency number immediately. This information is for educational purposes only."""},
        ]
        
        # Add conversation history (limit to last 10 messages to prevent tokens limit issues)
        messages.extend(conversations[session_id][-10:])
        
        logger.info(f"Sending request to OpenAI for session {session_id}")
        
        # Check if this is the first message in the conversation
        is_first_message = len(conversations[session_id]) <= 1
        
        # Call OpenAI API
        try:
            completion = client.chat.completions.create(
                model="gpt-4",  # Using GPT-4 for better format adherence
                messages=messages,
                temperature=0.5,  # Lower temperature for more consistent formatting
                max_tokens=1000,  # Increased token limit for complete responses
                presence_penalty=0.6,  # Encourage varied responses while maintaining format
                frequency_penalty=0.2  # Reduce repetition
            )
            
            # Extract the response
            ai_response = completion.choices[0].message.content
            
            # For first-time users, ensure only the seven standard questions are shown
            if is_first_message:
                questions = "\n".join(STANDARD_QUESTIONS)
                ai_response = f"To properly assess your condition, please answer these questions:\n\n{questions}\n\nPlease provide answers to these questions so I can better assist you."
            
            # Add AI response to conversation history
            conversations[session_id].append({"role": "assistant", "content": ai_response})
            
            result = {
                "response": ai_response,
                "session_id": session_id,
                "has_audio": True  # Mark that this response can be played as audio
            }
            
            return jsonify(result), 200
            
        except Exception as e:
            logger.error(f"OpenAI API error: {str(e)}")
            # Fallback to template response if OpenAI fails
            fallback_response = "I'm sorry, I encountered an error processing your request. If you're experiencing a medical emergency, please call 911 or visit your nearest emergency room immediately."
            
            return jsonify({
                "response": fallback_response,
                "session_id": session_id,
                "has_audio": True
            }), 200
    
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/chat", methods=["DELETE"])
def clear_conversation():
    """Clear conversation history for a session"""
    try:
        data = request.json
        if not data or "session_id" not in data:
            return jsonify({"error": "Invalid request. 'session_id' field is required"}), 400
            
        session_id = data.get("session_id")
        
        # Clear conversation history
        if session_id in conversations:
            conversations[session_id] = []
            
        return jsonify({"status": "success", "message": "Conversation cleared"}), 200
        
    except Exception as e:
        logger.error(f"Error clearing conversation: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = args.port
    debug_mode = os.getenv("FLASK_DEBUG", "False").lower() == "true"
    logger.info(f"Starting server on port {port}")
    app.run(host=os.getenv("SERVER_HOST", "0.0.0.0"), port=port, debug=debug_mode) 