#!/bin/bash

echo "### Krok 1: Usuwanie istniejących kontenerów i obrazów Dockera ###"
docker-compose down
docker system prune -a -f

echo "### Krok 2: Tworzenie struktury katalogów ###"
mkdir -p my_project/app/templates my_project/tests

echo "### Krok 3: Aktualizacja plików ###"
cat > my_project/app/__init__.py <<EOL
from flask import Flask

def create_app():
    app = Flask(__name__)
    app.config.from_object('app.config.Config')

    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app
EOL

cat > my_project/app/config.py <<EOL
class Config:
    SECRET_KEY = 'supersecretkey'
EOL

cat > my_project/app/main.py <<EOL
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

cat > my_project/app/requirements.txt <<EOL
Flask==2.1.1
Werkzeug==2.0.3
EOL

cat > my_project/app/wsgi.py <<EOL
from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run()
EOL

cat > my_project/app/templates/index.html <<EOL
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
 

