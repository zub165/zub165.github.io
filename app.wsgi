#!/usr/bin/env python3
import sys
import os
from dotenv import load_dotenv

# Add the application directory to the Python path
sys.path.insert(0, os.path.dirname(__file__))

# Load environment variables from .env file
load_dotenv()

# Import the Flask application
from app import app as application 