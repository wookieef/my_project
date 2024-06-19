#!/bin/bash

# Update and install necessary packages
echo "2424" | sudo -S apt update -y
echo "2424" | sudo -S apt upgrade -y

# Remove conflicting packages
echo "2424" | sudo -S apt remove -y containerd containerd.io
echo "2424" | sudo -S apt autoremove -y

# Install Docker using the official script
curl -fsSL https://get.docker.com -o get-docker.sh
echo "2424" | sudo -S sh get-docker.sh

# Add user to the docker group
echo "2424" | sudo -S usermod -aG docker wookiee

# Remove orphan containers
docker-compose down --remove-orphans

# Remove all Docker images if there are any
docker rmi -f $(docker images -a -q) || true

# Create project directory structure
mkdir -p app tests

# Create necessary files
touch app/__init__.py app/main.py app/config.py app/requirements.txt
touch tests/__init__.py tests/test_main.py
touch Dockerfile docker-compose.yml

# Write content to the files

# app/__init__.py
echo "# Initialize the app" > app/__init__.py

# app/main.py
cat <<EOL > app/main.py
from flask import Flask, jsonify, request
from config import Config
import subprocess

app = Flask(__name__)
app.config.from_object(Config)

@app.route('/')
def home():
    return jsonify({"message": "Hello, world!"})

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

# app/config.py
echo "class Config:
    DEBUG = True
    TESTING = False
    SECRET_KEY = 'your_secret_key'" > app/config.py

# app/requirements.txt
echo "flask
requests" > app/requirements.txt

# tests/__init__.py
echo "# Initialize the test package" > tests/__init__.py

# tests/test_main.py
cat <<EOL > tests/test_main.py
import unittest
from app.main import app

class MainTestCase(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_home(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"message": "Hello, world!"})

    def test_execute(self):
        response = self.app.post('/execute', json={"command": "echo Hello"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"output": "Hello\\n"})

if __name__ == '__main__':
    unittest.main()
EOL

# Dockerfile
cat <<EOL > Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt /app/
RUN pip install -r requirements.txt

COPY app /app

CMD ["python", "main.py"]
EOL

# docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./app:/app
EOL

# Make setup.sh executable
chmod +x setup.sh

# Build and run the Docker container
docker-compose up --build -d

echo "Setup complete. Docker container is running the project."

