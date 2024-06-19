#!/bin/bash

echo "### Krok 1: Usuwanie istniejących kontenerów i obrazów Dockera ###"
docker-compose down
docker system prune -a -f

echo "### Krok 2: Tworzenie struktury katalogów ###"
mkdir -p app/templates tests

echo "### Krok 3: Przywracanie plików ###"

cat > app/__init__.py <<EOL
from flask import Flask

def create_app():
    app = Flask(__name__)
    app.config.from_object('config.Config')

    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app
EOL

cat > app/config.py <<EOL
class Config:
    SECRET_KEY = 'supersecretkey'
EOL

cat > app/main.py <<EOL
from flask import Blueprint, request, jsonify
import subprocess

main = Blueprint('main', __name__)

@main.route('/chat', methods=['POST'])
def chat():
    data = request.json
    message = data.get('message')
    response = f"I received your message: {message}"
    return jsonify({'response': response})

@main.route('/execute', methods=['POST'])
def execute():
    data = request.json
    command = data.get('command')
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return jsonify({'output': result.stdout})
EOL

cat > app/requirements.txt <<EOL
Flask==2.1.1
EOL

cat > app/templates/index.html <<EOL
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Chat Interface</title>
</head>
<body>
  <h1>Chat with AI</h1>
  <form id="chat-form">
    <input type="text" id="message" name="message" placeholder="Type your message">
    <button type="submit">Send</button>
  </form>
  <div id="response"></div>

  <script>
    document.getElementById('chat-form').addEventListener('submit', async function(e) {
      e.preventDefault();
      const message = document.getElementById('message').value;
      const response = await fetch('/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message })
      });
      const data = await response.json();
      document.getElementById('response').innerText = data.response;
    });
  </script>
</body>
</html>
EOL

cat > diagnose.sh <<EOL
#!/bin/bash

echo "Fetching Docker logs for the Flask container..."
docker logs my_project_app_1

echo "Flask container is not running. Attempting to restart..."
docker-compose down
docker-compose up -d

echo "Testing Flask server..."
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000)
if [ "\$status" -ne 200 ]; then
    echo "Flask server is not responding correctly. HTTP status code: \$status"
    echo "Fetching latest Docker logs..."
    docker logs my_project_app_1
else
    echo "Flask server is running correctly."
fi
EOL

chmod +x diagnose.sh

cat > docker-compose.yml <<EOL
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    restart: unless-stopped
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
EOL

cat > Dockerfile <<EOL
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app /app

CMD ["python3", "main.py"]
EOL

cat > setup.sh <<EOL
#!/bin/bash

echo "Creating network 'my_project_default'..."
docker network create my_project_default

echo "Building Docker images..."
docker-compose build

echo "Starting Docker containers..."
docker-compose up -d

echo "Setup complete. Docker containers are running the project."
EOL

chmod +x setup.sh

cat > full_setup.sh <<EOL
#!/bin/bash

echo "### Krok 1: Przygotowanie środowiska ###"
sudo apt-get update
sudo apt-get install -y python3 python3-pip docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "### Krok 2: Klonowanie repozytorium ###"
echo "Repozytorium klonowane lokalnie"
mkdir -p app templates tests

echo "### Krok 3: Tworzenie plików konfiguracyjnych ###"
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    restart: unless-stopped
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
EOF

cat > Dockerfile <<EOF
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app /app

CMD ["python3", "main.py"]
EOF

echo "### Krok 4: Budowanie i uruchamianie kontenerów ###"
docker-compose down
docker-compose up --build -d

echo "### Krok 5: Testowanie serwera Flask ###"
sleep 10  # Czekaj na uruchomienie kontenerów
curl -X POST http://localhost:5000/chat -H "Content-Type: application/json" -d '{"message":"Hello"}'

echo "### Krok 6: Diagnozowanie problemów ###"
./diagnose.sh
EOL

chmod +x full_setup.sh

cat > tests/__init__.py <<EOL
# This file can be empty or contain initialization code for your tests
EOL

cat > tests/test_main.py <<EOL
import unittest
from app.main import create_app

class MainTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()

    def test_chat_endpoint(self):
        response = self.client.post('/chat', json={'message': 'Hello'})
        data = response.get_json()
        self.assertEqual(response.status_code, 200)
        self.assertIn('I received your message: Hello', data['response'])

    def test_execute_endpoint(self):
        response = self.client.post('/execute', json={'command': 'echo Hello'})
        data = response.get_json()
        self.assertEqual(response.status_code, 200)
        self.assertIn('Hello', data['output'])

if __name__ == '__main__':
    unittest.main()
EOL

echo "### Krok 4: Budowanie i uruchamianie kontenerów ###"
docker-compose down
docker-compose up --build -d

echo "### Krok 5: Testowanie serwera Flask ###"
sleep 10  # Czekaj na uruchomienie kontenerów
curl -X POST http://localhost:5000/chat -H "Content-Type: application/json" -d '{"message":"Hello"}'

echo "### Krok 6: Diagnozowanie problemów ###"
./diagnose.sh
