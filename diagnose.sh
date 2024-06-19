#!/bin/bash

# Fetch Docker logs for the Flask container
echo "Fetching Docker logs for the Flask container..."
docker-compose logs app

# Check if the Flask container is running
container_status=$(docker inspect -f '{{.State.Running}}' my_project_app_1)

if [ "$container_status" == "true" ]; then
  echo "Flask container is running."
else
  echo "Flask container is not running. Attempting to restart..."
  docker-compose restart app
fi

# Test the Flask server
echo "Testing Flask server..."
http_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000)

if [ "$http_status" == "200" ]; then
  echo "Flask server is responding correctly. HTTP status code: $http_status"
else
  echo "Flask server is not responding correctly. HTTP status code: $http_status"
  echo "Fetching latest Docker logs..."
  docker-compose logs app
fi

