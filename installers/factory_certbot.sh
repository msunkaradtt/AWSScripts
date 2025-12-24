#!/bin/bash

# ==============================================================================
# Factory Certbot
# Author: Mohith Bhargav Sunkara
# Date: 2025-12-24
# Version: 1.0.0
# ==============================================================================
# A script to install Certbot and request an SSL certificate.
#
# Usage: sudo ./factory_certbot.sh
# ==============================================================================

# Colors for log messages
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m" # No Color

# Function to install Certbot (Standalone version)
install_certbot() {
    echo -e "${YELLOW}Updating package list and installing Certbot...${NC}"
    # Removed python3-certbot-nginx to prevent host-level Nginx interference
    sudo apt update && sudo apt install -y certbot

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Certbot. Please check your internet connection and package sources.${NC}"
        exit 1
    else
        echo -e "${GREEN}Certbot installed successfully!${NC}"
    fi
}

# Function to request an SSL certificate using Standalone mode
request_ssl_certificate() {
    # Prompt user for domain and email
    read -p "Enter the domain name for the SSL certificate (e.g., example.com): " DOMAIN
    read -p "Enter your email address for registration and renewal notices: " EMAIL

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
    
    # IMPORTANT: 
    # 1. We use 'certonly' so Certbot doesn't try to install the cert into a local Nginx.
    # 2. We use '--standalone' which runs a temporary webserver to verify the domain.
    # NOTE: You MUST temporarily stop your Docker Nginx container (port 80) for this to work.
    sudo certbot certonly --standalone -d "$DOMAIN" --agree-tos --email "$EMAIL" --non-interactive

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL certificate successfully obtained for $DOMAIN!${NC}"
        echo -e "${YELLOW}Certificates are located in: /etc/letsencrypt/live/$DOMAIN/${NC}"
    else
        echo -e "${RED}Failed to obtain SSL certificate. Check the logs above for details.${NC}"
        exit 1
    fi
}

# Function to remove an existing SSL certificate
remove_ssl_certificate() {
    echo -e "${YELLOW}Listing existing certificates...${NC}"
    sudo certbot certificates

    echo -e "${YELLOW}Please review the list above.${NC}"
    read -p "Enter the exact Certificate Name of the certificate to remove: " CERT_NAME

    if [[ -z "$CERT_NAME" ]]; then
        echo -e "${RED}Error: Certificate name cannot be empty.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Attempting to remove certificate: ${GREEN}$CERT_NAME${NC}"
    sudo certbot delete --cert-name "$CERT_NAME" --non-interactive

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate $CERT_NAME has been successfully removed.${NC}"
    else
        echo -e "${RED}Failed to remove certificate $CERT_NAME.${NC}"
        exit 1
    fi
}

# --- Main Menu ---
echo -e "${YELLOW}Certbot Management Script (Docker-Friendly)${NC}"
echo "--------------------------"
echo "Select an option:"
echo "1. Install Certbot only"
echo "2. Install Certbot and request an SSL certificate"
echo "3. Request an SSL certificate (if Certbot is already installed)"
echo -e "4. ${RED}Remove an existing SSL certificate${NC}"
read -p "Enter your choice (1/2/3/4): " CHOICE

case $CHOICE in
    1) install_certbot ;;
    2) install_certbot; request_ssl_certificate ;;
    3) request_ssl_certificate ;;
    4) remove_ssl_certificate ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        exit 1
        ;;
esac