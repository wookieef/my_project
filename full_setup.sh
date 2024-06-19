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
