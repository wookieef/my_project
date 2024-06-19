#!/bin/bash

# Stop and remove existing containers
docker-compose down

# Remove all Docker images related to the project
docker rmi -f $(docker images -q my_project_app)

# Ensure necessary directories and files are present
PROJECT_DIR=~/Pulpit/my_project
APP_DIR=$PROJECT_DIR/app

# Check if main.py exists
if [ ! -f "$APP_DIR/main.py" ]; then
    echo "main.py not found in $APP_DIR"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
    echo "Dockerfile not found in $PROJECT_DIR"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "docker-compose.yml not found in $PROJECT_DIR"
    exit 1
fi

# Build and start containers
docker-compose up --build -d

# Check status of containers
echo "Checking status of containers..."
docker ps -a

# Wait for a few seconds to ensure containers have started
sleep 5

# Get logs of the Flask app container
echo "Fetching logs of the Flask app container..."
docker logs my_project_app_1

# Check if the Flask container is running
FLASK_CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' my_project_app_1)

if [ "$FLASK_CONTAINER_STATUS" != "running" ]; then
  echo "Flask app container is not running. Checking detailed logs..."
  docker logs my_project_app_1
  echo "Attempting to start Flask app container manually..."
  docker start my_project_app_1
  docker exec -it my_project_app_1 /bin/bash -c "ls /app && python3 /app/main.py"
else
  echo "Flask app container is running successfully."
fi

echo "Setup complete. Containers are running."
