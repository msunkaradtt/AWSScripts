#!/bin/bash

set -e  # Exit on any error

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
sudo apt-get update -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
    sudo apt-get install docker.io -y
    echo -e "${YELLOW}Starting and enabling Docker service...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker

    # Verify Docker installation
    if docker --version &> /dev/null; then
        echo -e "${GREEN}Docker installed successfully: $(docker --version)${NC}"
    else
        echo -e "${RED}Docker installation failed.${NC}" >&2
        exit 1
    fi
else
    echo -e "${GREEN}Docker already installed: $(docker --version)${NC}"
fi

# Add user to the Docker group (always ensure membership)
echo -e "${YELLOW}Adding user to Docker group...${NC}"
sudo usermod -aG docker "$(whoami)"
exec newgrp docker

# Install NVIDIA Container Toolkit if not present
if ! command -v nvidia-ctk &> /dev/null; then
    echo -e "${YELLOW}NVIDIA Container Toolkit not found. Installing...${NC}"
    # Add repo and key
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    echo -e "${YELLOW}Updating package list (with NVIDIA repo)...${NC}"
    sudo apt-get update -y

    echo -e "${YELLOW}Installing NVIDIA Container Toolkit...${NC}"
    sudo apt-get install -y nvidia-container-toolkit

    echo -e "${YELLOW}Configuring Docker to use NVIDIA runtime...${NC}"
    sudo nvidia-ctk runtime configure --runtime=docker

    echo -e "${YELLOW}Restarting Docker service...${NC}"
    sudo systemctl restart docker

    # Verify NVIDIA Container Toolkit installation
    if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi &> /dev/null; then
        echo -e "${GREEN}NVIDIA Container Toolkit installed successfully and GPU access verified.${NC}"
    else
        echo -e "${RED}NVIDIA Container Toolkit installation or GPU access verification failed.${NC}" >&2
        exit 1
    fi
else
    echo -e "${GREEN}NVIDIA Container Toolkit already installed: $(nvidia-ctk --version || echo 'version info unavailable')${NC}"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose not found. Installing...${NC}"
    COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
    DEST_PATH="/usr/local/bin/docker-compose"

    echo -e "${YELLOW}Downloading Docker Compose from $COMPOSE_URL...${NC}"
    sudo curl -L "$COMPOSE_URL" -o "$DEST_PATH"

    echo -e "${YELLOW}Setting execution permissions for Docker Compose...${NC}"
    sudo chmod +x "$DEST_PATH"

    # Verify Docker Compose installation
    if docker-compose --version &> /dev/null; then
        echo -e "${GREEN}Docker Compose installed successfully: $(docker-compose --version)${NC}"
    else
        echo -e "${RED}Docker Compose installation failed.${NC}" >&2
        exit 1
    fi
else
    echo -e "${GREEN}Docker Compose already installed: $(docker-compose --version)${NC}"
fi

echo -e "${GREEN}All requested components are present and up to date!${NC}"