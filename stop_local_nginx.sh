#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    local port=$1
    sudo lsof -i :$port &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Port $port is in use.${NC}"
        return 0
    else
        echo -e "${GREEN}Port $port is free.${NC}"
        return 1
    fi
}

# Check if ports 80 and 443 are in use
check_port 80
port_80_in_use=$?

check_port 443
port_443_in_use=$?

# Stop and disable Nginx if either port 80 or 443 is in use
if [[ $port_80_in_use -eq 0 || $port_443_in_use -eq 0 ]]; then
    echo -e "${RED}Stopping Nginx service...${NC}"
    sudo systemctl stop nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx service stopped successfully.${NC}"
    else
        echo -e "${RED}Failed to stop Nginx service.${NC}"
    fi

    echo -e "${RED}Disabling Nginx service...${NC}"
    sudo systemctl disable nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Nginx service disabled successfully.${NC}"
    else
        echo -e "${RED}Failed to disable Nginx service.${NC}"
    fi
else
    echo -e "${GREEN}Ports 80 and 443 are not in use. No action needed.${NC}"
fi

# Final check to see if ports 80 and 443 are still in use
echo -e "${YELLOW}Checking ports 80 and 443 again...${NC}"
sudo lsof -i :80
sudo lsof -i :443