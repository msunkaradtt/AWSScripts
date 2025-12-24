<#
.SYNOPSIS
    Automated Remote Deployment Script
.DESCRIPTION
    1. Selects SSH key.
    2. Connects to AWS.
    3. Performs interactive navigation, Docker management, and GitHub release deployment.
# ==============================================================================
# Deploy App
# Author: Mohith Bhargav Sunkara
# Date: 2025-12-24
# Version: 1.0.0
# ==============================================================================
# A script to deploy an application to a remote server.
#
# Usage: .\Deploy-App.ps1
# ==============================================================================
#>

# --- Configuration for Colors ---
$colorHeader = "Cyan"
$colorPrompt = "Yellow"
$colorSuccess = "Green"
$colorError = "Red"
$colorInfo = "White"

function Write-Header {
    param($Text)
    Write-Host "`n========================================================" -ForegroundColor $colorHeader
    Write-Host "  $Text" -ForegroundColor $colorHeader
    Write-Host "========================================================`n" -ForegroundColor $colorHeader
}

Write-Header "AWS INTERACTIVE DEPLOYMENT ASSISTANT"

# -------------------------------------------------------------------------
# STEP 1: Select SSH Key
# -------------------------------------------------------------------------
Write-Host "[Step 1] Scanning for SSH keys in current directory..." -ForegroundColor $colorInfo

# Get .pem, .ppk, or files starting with id_
$keys = Get-ChildItem -Path . -File | Where-Object { $_.Extension -match "\.(pem|ppk)" -or $_.Name -match "^id_" }

if ($keys.Count -eq 0) {
    Write-Host "Error: No SSH key files (.pem, .ppk, id_*) found in this directory." -ForegroundColor $colorError
    exit
}

$i = 1
foreach ($k in $keys) {
    Write-Host "  [$i] $($k.Name)" -ForegroundColor $colorInfo
    $i++
}

$selection = Read-Host -Prompt "Select Key File (Enter number)"
try {
    $selectedKey = $keys[$selection - 1].FullName
    Write-Host "Selected: $selectedKey" -ForegroundColor $colorSuccess
}
catch {
    Write-Host "Invalid selection. Exiting." -ForegroundColor $colorError
    exit
}

# -------------------------------------------------------------------------
# STEP 2: Connection Details
# -------------------------------------------------------------------------
Write-Host "`n[Step 2] Connection Details" -ForegroundColor $colorInfo
$sshUser = Read-Host -Prompt "Enter SSH User (e.g., ubuntu, ec2-user)"
$awsIp   = Read-Host -Prompt "Enter AWS Server IP/DNS"

if (-not $sshUser -or -not $awsIp) {
    Write-Host "Missing details. Exiting." -ForegroundColor $colorError
    exit
}

# -------------------------------------------------------------------------
# GENERATE REMOTE BASH SCRIPT
# -------------------------------------------------------------------------
# We create the logic that runs ON the Linux server here.
# We use a single-quoted Here-String so PowerShell doesn't try to interpret the $ variables.

$remoteScriptContent = @'
#!/bin/bash

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Successfully connected to server.${NC}"

# --- STEP 3: Navigate Interactive ---
while true; do
    echo -e "\n${YELLOW}Current Directory: $(pwd)${NC}"
    echo "Files here:"
    ls -F --group-directories-first
    
    echo -e "\nWhere would you like to go?"
    read -p "Enter folder name (or type 'here' to select this folder): " targetDir
    
    if [ "$targetDir" == "here" ] || [ "$targetDir" == "." ]; then
        PROJECT_DIR=$(pwd)
        echo -e "${GREEN}Project folder selected: $PROJECT_DIR${NC}"
        break
    elif [ -d "$targetDir" ]; then
        cd "$targetDir"
    else
        echo -e "${RED}Directory not found. Try again.${NC}"
    fi
done

# --- STEP 4: Docker Compose Down ---
echo -e "\n${CYAN}[Check] Checking for docker-compose...${NC}"
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "Found docker-compose file."
    
    # Check if running
    if docker-compose ps | grep "Up" > /dev/null; then
        echo -e "${YELLOW}Services are running. Shutting down...${NC}"
        docker-compose down
    else
        echo "Services are not currently running."
    fi
else
    echo -e "${RED}Warning: No docker-compose.yml found in this folder.${NC}"
fi

# --- STEP 5: Check WWW and Cleanup ---
if [ -d "www" ]; then
    echo -e "\n${CYAN}[Clean] Found 'www' folder. Contents:${NC}"
    ls -F www/
    
    read -p "Do you want to DELETE contents of 'www' to upload new files? (yes/no): " delConfirm
    if [[ "$delConfirm" =~ ^[Yy]es$ ]]; then
        echo -e "${YELLOW}Deleting contents of www...${NC}"
        rm -rf www/*
        echo -e "${GREEN}Cleaned.${NC}"
    else
        echo "Skipping deletion."
    fi
else
    echo -e "\n${YELLOW}'www' folder not found. Creating it...${NC}"
    mkdir www
fi

# --- STEP 6 & 7: Download and Unzip ---
read -p "Enter GitHub Release .zip URL: " zipUrl

if [ ! -z "$zipUrl" ]; then
    echo -e "\n${CYAN}[Download] Downloading release...${NC}"
    wget -q --show-progress "$zipUrl" -O update.zip
    
    if [ -f "update.zip" ]; then
        echo -e "${CYAN}[Unzip] Unzipping to 'www'...${NC}"
        # Unzip into www (adjusting commands if zip contains a root folder may be needed, assuming flat or standard structure)
        unzip -o update.zip -d www/
        
        echo -e "${YELLOW}[Cleanup] Removing zip file...${NC}"
        rm update.zip
        echo -e "${GREEN}Files updated.${NC}"
    else
        echo -e "${RED}Download failed.${NC}"
    fi
else
    echo "No URL provided. Skipping download."
fi

# --- STEP 8: Start Services ---
echo -e "\n${CYAN}[Start] Ready to start services.${NC}"
read -p "Run 'docker-compose up -d'? (yes/no): " startConfirm

if [[ "$startConfirm" =~ ^[Yy]es$ ]]; then
    docker-compose up -d
    if [ $? -eq 0 ]; then
         echo -e "${GREEN}Services started successfully!${NC}"
    else
         echo -e "${RED}Failed to start services.${NC}"
    fi
fi

echo -e "\n============================================="
echo -e "           ${GREEN}DEPLOYMENT SUMMARY${NC}"
echo -e "============================================="
echo -e "1. Navigated to: $PROJECT_DIR"
echo -e "2. Docker Services: Reset/Updated"
echo -e "3. Web Assets: Refreshed in /www"
echo -e "---------------------------------------------"
echo -e "${CYAN}Coding is an art, and you are the artist."
echo -e "Keep building amazing things!${NC}"
echo -e "============================================="

'@

# Save the bash script to a temp file locally
$tempScript = ".\temp_deploy_$(Get-Random).sh"
Set-Content -Path $tempScript -Value $remoteScriptContent -Encoding UTF8 -NoNewline

# -------------------------------------------------------------------------
# EXECUTION: SCP and SSH
# -------------------------------------------------------------------------
Write-Header "CONNECTING TO REMOTE SERVER"

try {
    # 1. Upload the script to the temp folder on the server
    Write-Host "Uploading helper script..." -ForegroundColor $colorInfo
    scp -i "$selectedKey" -o StrictHostKeyChecking=no $tempScript "${sshUser}@${awsIp}:/tmp/remote_deploy.sh"

    # 2. Make it executable and Run it interactively (-t is crucial here)
    Write-Host "Starting interactive remote session...`n" -ForegroundColor $colorSuccess
    
    # We use -t to allocate a TTY so the remote `read` commands work
    ssh -t -i "$selectedKey" -o StrictHostKeyChecking=no "${sshUser}@${awsIp}" "chmod +x /tmp/remote_deploy.sh && bash /tmp/remote_deploy.sh && rm /tmp/remote_deploy.sh"

}
catch {
    Write-Host "An error occurred during SSH connection: $_" -ForegroundColor $colorError
}
finally {
    # Cleanup local temp file
    if (Test-Path $tempScript) {
        Remove-Item $tempScript
    }
    
    Write-Header "DISCONNECTED"
    Write-Host "Thank you for using the deployment tool." -ForegroundColor $colorSuccess
}