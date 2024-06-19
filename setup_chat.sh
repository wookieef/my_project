#!/bin/bash

echo "Stopping all running Docker containers..."
if [ "$(docker ps -q)" ]; then
    docker stop $(docker ps -q)
fi

echo "Removing all Docker containers..."
if [ "$(docker ps -a -q)" ]; then
    docker rm $(docker ps -a -q)
fi

echo "Removing all Docker images..."
if [ "$(docker images -q)" ]; then
    docker rmi $(docker images -q)
fi

echo "Removing Docker volumes..."
if [ "$(docker volume ls -q)" ]; then
    docker volume rm $(docker volume ls -q)
fi

echo "Removing Docker networks..."
docker network rm $(docker network ls -q | grep -v "bridge\|host\|none")

echo "Cleaning up dangling Docker resources..."
docker system prune -f

echo "Environment cleanup complete."

echo "Installing Docker and Docker Compose..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Building and starting the Docker containers..."
docker-compose up --build -d

echo "Setup complete. Docker container is running the project."

