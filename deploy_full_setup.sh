#!/bin/bash

# Define the project directory
PROJECT_DIR=~/Pulpit/my_project

# Remove the existing 'src' directory if it exists
rm -rf $PROJECT_DIR/app/src

# Create the necessary directories and files
mkdir -p $PROJECT_DIR/app/templates
mkdir -p $PROJECT_DIR/tests
mkdir -p $PROJECT_DIR/prometheus
mkdir -p $PROJECT_DIR/grafana

# Create the necessary files
touch $PROJECT_DIR/app/__init__.py $PROJECT_DIR/app/main.py $PROJECT_DIR/app/config.py $PROJECT_DIR/app/requirements.txt
touch $PROJECT_DIR/tests/__init__.py $PROJECT_DIR/tests/test_main.py
touch $PROJECT_DIR/Dockerfile $PROJECT_DIR/docker-compose.yml
touch $PROJECT_DIR/prometheus/prometheus.yml

# Update and install necessary packages
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y docker.io docker-compose python3-pip

# Add current user to the docker group
sudo usermod -aG docker $USER

# Install Python packages
pip3 install tensorflow scikit-learn pytest

# Write content to the files

# app/__init__.py
echo "# Initialize the app" > $PROJECT_DIR/app/__init__.py

# app/main.py
cat <<EOL > $PROJECT_DIR/app/main.py
from flask import Flask, jsonify, request, render_template
from config import Config
import subprocess
import tensorflow as tf
import numpy as np

app = Flask(__name__)
app.config.from_object(Config)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/execute', methods=['POST'])
def execute():
    data = request.json
    command = data.get('command')
    if command:
        try:
            result = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
            return jsonify({"output": result.decode('utf-8')})
        except subprocess.CalledProcessError as e:
            return jsonify({"error": e.output.decode('utf-8')}), 400
    return jsonify({"error": "No command provided"}), 400

@app.route('/chat', methods=['POST'])
def chat():
    data = request.json
    message = data.get('message')
    if message:
        # Placeholder for AI model response, replace with actual model inference
        response = f"I received your message: {message}"
        return jsonify({"response": response})
    return jsonify({"error": "No message provided"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

# app/config.py
cat <<EOL > $PROJECT_DIR/app/config.py
class Config:
    DEBUG = True
    TESTING = False
    SECRET_KEY = 'your_secret_key'
EOL

# app/requirements.txt
echo -e "flask\ntensorflow\nscikit-learn" > $PROJECT_DIR/app/requirements.txt

# app/templates/index.html
cat <<EOL > $PROJECT_DIR/app/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat Interface</title>
    <script>
        async function sendMessage() {
            const message = document.getElementById('message').value;
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: message }),
            });
            const data = await response.json();
            document.getElementById('chatbox').innerText += \`You: \${message}\nAI: \${data.response}\n\`;
            document.getElementById('message').value = '';
        }
    </script>
</head>
<body>
    <h1>Chat Interface</h1>
    <div id="chatbox" style="width: 500px; height: 400px; border: 1px solid #000; overflow-y: scroll; padding: 10px;"></div>
    <input type="text" id="message" style="width: 400px;">
    <button onclick="sendMessage()">Send</button>
</body>
</html>
EOL

# tests/__init__.py
echo "# Initialize the test package" > $PROJECT_DIR/tests/__init__.py

# tests/test_main.py
cat <<EOL > $PROJECT_DIR/tests/test_main.py
import unittest
from app.main import app

class MainTestCase(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_home(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode('utf-8'), "Hello, world!")

    def test_execute(self):
        response = self.app.post('/execute', json={"command": "echo Hello"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"output": "Hello\\n"})

    def test_chat(self):
        response = self.app.post('/chat', json={"message": "Hello"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"response": "I received your message: Hello"})

if __name__ == '__main__':
    unittest.main()
EOL

# Dockerfile
cat <<EOL > $PROJECT_DIR/Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt /app/
RUN pip install -r requirements.txt

COPY app /app

CMD ["python", "main.py"]
EOL

# docker-compose.yml
cat <<EOL > $PROJECT_DIR/docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./app:/app
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
EOL

# prometheus/prometheus.yml
cat <<EOL > $PROJECT_DIR/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flask_app'
    static_configs:
      - targets: ['app:5000']
EOL

# Build and run the Docker container
cd $PROJECT_DIR
docker-compose down --rmi all
docker-compose up --build -d

echo "Setup complete. Docker container is running the project."
