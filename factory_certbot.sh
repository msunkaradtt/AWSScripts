#!/bin/bash

# Colors for log messages
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m" # No Color

# Function to install Certbot
install_certbot() {
    echo -e "${YELLOW}Updating package list and installing Certbot...${NC}"
    sudo apt update && sudo apt install -y certbot python3-certbot-nginx

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Certbot. Please check your internet connection and package sources.${NC}"
        exit 1
    else
        echo -e "${GREEN}Certbot installed successfully!${NC}"
    fi
}

# Function to request an SSL certificate
request_ssl_certificate() {
    # Prompt user for domain and email
    read -p "Enter the domain name for SSL certificate (e.g., example.com): " DOMAIN
    read -p "Enter your email address for SSL certificate registration: " EMAIL

    # Validate inputs
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}Error: Domain name cannot be empty.${NC}"
        exit 1
    fi

    if [[ -z "$EMAIL" ]]; then
        echo -e "${RED}Error: Email address cannot be empty.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Requesting SSL certificate for domain: ${GREEN}$DOMAIN${NC}"
    sudo certbot certonly --nginx -d "$DOMAIN" --agree-tos --email "$EMAIL" --non-interactive

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL certificate successfully obtained for $DOMAIN!${NC}"
    else
        echo -e "${RED}Failed to obtain SSL certificate. Check the logs above for details.${NC}"
        exit 1
    fi
}

# Menu function
echo -e "${YELLOW}Select an option:${NC}"
echo "1. Install Certbot only"
echo "2. Install Certbot and request an SSL certificate"
echo "3. Request an SSL certificate only (if Certbot is already installed)"
read -p "Enter your choice (1/2/3): " CHOICE

case $CHOICE in
    1)
        install_certbot
        ;;
    2)
        install_certbot
        request_ssl_certificate
        ;;
    3)
        request_ssl_certificate
        ;;
    *)
        echo -e "${RED}Invalid option. Please run the script again and select a valid option.${NC}"
        exit 1
        ;;
esac
