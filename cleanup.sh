#!/bin/bash

# Stop all running Docker containers
echo "Stopping all running Docker containers..."
echo "2424" | sudo -S docker ps -q | xargs -r docker stop

# Remove all Docker containers
echo "Removing all Docker containers..."
echo "2424" | sudo -S docker ps -aq | xargs -r docker rm

# Remove all Docker images
echo "Removing all Docker images..."
echo "2424" | sudo -S docker images -aq | xargs -r docker rmi -f

# Remove Docker volumes
echo "Removing Docker volumes..."
echo "2424" | sudo -S docker volume ls -q | xargs -r docker volume rm

# Remove Docker networks
echo "Removing Docker networks..."
echo "2424" | sudo -S docker network ls -q | xargs -r docker network rm

# Clean up dangling images, containers, volumes, and networks
echo "Cleaning up dangling Docker resources..."
echo "2424" | sudo -S docker system prune -af --volumes

echo "Environment cleanup complete."

