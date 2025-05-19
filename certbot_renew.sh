#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project folder (change this to your project folder)
PROJECT_FOLDER="/path/to/your/project"

# Function to check if any containers are still running
check_containers_down() {
    local attempts=0
    local max_attempts=30
    local wait_seconds=2
    
    while [[ $attempts -lt $max_attempts ]]; do
        if docker-compose ps | grep -q "Up"; then
            echo -e "${YELLOW}Waiting for containers to stop... (attempt $((attempts+1))${NC}"
            sleep $wait_seconds
            ((attempts++))
        else
            echo -e "${GREEN}All containers are down.${NC}"
            return 0
        fi
    done
    
    echo -e "${RED}Error: Containers did not stop within the expected time.${NC}"
    return 1
}

# Main script execution
echo -e "${BLUE}Moving to project folder: $PROJECT_FOLDER${NC}"
cd "$PROJECT_FOLDER" || { echo -e "${RED}Failed to change to project folder!${NC}"; exit 1; }

echo -e "${BLUE}Stopping containers with docker-compose down...${NC}"
docker-compose down || { echo -e "${RED}Error during docker-compose down!${NC}"; exit 1; }

check_containers_down || exit 1

echo -e "${BLUE}Running certbot renew...${NC}"
certbot renew || { echo -e "${RED}Error during certbot renew!${NC}"; exit 1; }
echo -e "${GREEN}Certbot renew completed successfully.${NC}"

echo -e "${BLUE}Starting containers with docker-compose up -d...${NC}"
docker-compose up -d || { echo -e "${RED}Error during docker-compose up!${NC}"; exit 1; }
echo -e "${GREEN}Containers started successfully.${NC}"

echo -e "${GREEN}Script completed successfully!${NC}"