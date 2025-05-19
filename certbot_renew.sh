#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to find project folder in home directory
find_project_folder() {
    local folder_name="$1"
    local found_path=""
    
    echo -e "${CYAN}Searching for project folder '$folder_name' in home directory...${NC}"
    
    # Search in home directory and immediate subdirectories
    found_path=$(find "$HOME" -maxdepth 2 -type d -name "$folder_name" -print -quit)
    
    if [[ -z "$found_path" ]]; then
        echo -e "${RED}Error: Project folder '$folder_name' not found in home directory or its immediate subdirectories.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Found project folder at: $found_path${NC}"
    echo "$found_path"
    return 0
}

# Function to check if any containers are still running
# check_containers_down() {
#     local attempts=0
#     local max_attempts=30
#     local wait_seconds=2
    
#     while [[ $attempts -lt $max_attempts ]]; do
#         if docker-compose ps | grep -q "Up"; then
#             echo -e "${YELLOW}Waiting for containers to stop... (attempt $((attempts+1))${NC}"
#             sleep $wait_seconds
#             ((attempts++))
#         else
#             echo -e "${GREEN}All containers are down.${NC}"
#             return 0
#         fi
#     done
    
#     echo -e "${RED}Error: Containers did not stop within the expected time.${NC}"
#     return 1
# }

# Main script execution
echo -e "${CYAN}Please enter the name of your project folder:${NC}"
read -r project_folder_name

if [[ -z "$project_folder_name" ]]; then
    echo -e "${RED}Error: No project folder name provided.${NC}"
    exit 1
fi

project_path=$(find_project_folder "$project_folder_name") || exit 1

echo -e "${BLUE}Moving to project folder: $project_path${NC}"
cd "$project_path" || { echo -e "${RED}Failed to change to project folder!${NC}"; exit 1; }

# echo -e "${BLUE}Stopping containers with docker-compose down...${NC}"
# docker-compose down || { echo -e "${RED}Error during docker-compose down!${NC}"; exit 1; }

# check_containers_down || exit 1

# echo -e "${BLUE}Running certbot renew...${NC}"
# certbot renew || { echo -e "${RED}Error during certbot renew!${NC}"; exit 1; }
# echo -e "${GREEN}Certbot renew completed successfully.${NC}"

# echo -e "${BLUE}Starting containers with docker-compose up -d...${NC}"
# docker-compose up -d || { echo -e "${RED}Error during docker-compose up!${NC}"; exit 1; }
# echo -e "${GREEN}Containers started successfully.${NC}"

echo -e "${GREEN}Script completed successfully!${NC}"