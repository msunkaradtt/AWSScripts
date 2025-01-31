#!/bin/bash

set -e  # Exit on any error

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install docker.io -y

# Start and enable Docker service
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
docker --version &> /dev/null
if [ $? -eq 0 ]; then
    echo "Docker installed successfully: $(docker --version)"
else
    echo "Docker installation failed." >&2
    exit 1
fi

# Add user to the Docker group
echo "Adding user to Docker group..."
sudo usermod -aG docker $(whoami)
newgrp docker

# Download and install Docker Compose
COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
DEST_PATH="/usr/local/bin/docker-compose"

echo "Downloading Docker Compose from $COMPOSE_URL..."
sudo curl -L "$COMPOSE_URL" -o "$DEST_PATH"

# Make Docker Compose executable
echo "Setting execution permissions for Docker Compose..."
sudo chmod +x "$DEST_PATH"

# Verify Docker Compose installation
docker-compose --version &> /dev/null
if [ $? -eq 0 ]; then
    echo "Docker Compose installed successfully: $(docker-compose --version)"
else
    echo "Docker Compose installation failed." >&2
    exit 1
fi

echo "Docker and Docker Compose installation completed successfully!"
