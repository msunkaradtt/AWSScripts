#!/bin/bash

# ==============================================================================
# Certbot Certificate Manager
# ==============================================================================
# A script to list, check status, and renew Certbot SSL certificates interactively.
#
# Usage: sudo ./certbot_manager.sh
# ==============================================================================

# --- Colors and Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Check for Root Privileges ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: Please run as root (use sudo).${NC}"
  exit 1
fi

# --- Check if Certbot is installed ---
if ! command -v certbot &> /dev/null; then
    echo -e "${RED}Error: Certbot is not installed or not in your PATH.${NC}"
    exit 1
fi

echo -e "${BLUE}${BOLD}Fetching certificate data... Please wait.${NC}"
echo ""

# --- Variables ---
declare -a CERT_NAMES
declare -a CERT_DATES
declare -a CERT_STATUSES
current_name=""
current_date=""

# --- Parse Certbot Output ---
# We read the output of 'certbot certificates' line by line.
# Note: Output format is typically:
# Certificate Name: example.com
# ...
# Expiry Date: 2023-01-01 12:00:00+00:00 (VALID: 20 days)

raw_output=$(certbot certificates 2>/dev/null)

if [[ -z "$raw_output" ]]; then
    echo -e "${RED}Could not run certbot certificates or no output returned.${NC}"
    exit 1
fi

# Use a loop to parse the raw text
while IFS= read -r line; do
    # 1. Extract Certificate Name
    if [[ "$line" =~ "Certificate Name:" ]]; then
        current_name=$(echo "$line" | awk -F': ' '{print $2}' | tr -d ' ')
    fi

    # 2. Extract Expiry Date
    if [[ "$line" =~ "Expiry Date:" ]]; then
        # Extract the date string (remove "Expiry Date: " and anything after the first parenthesis)
        raw_date_line=$(echo "$line" | sed 's/.*Expiry Date: //')
        current_date=$(echo "$raw_date_line" | sed 's/ (.*//')
        
        # Add to arrays
        if [[ -n "$current_name" && -n "$current_date" ]]; then
            CERT_NAMES+=("$current_name")
            CERT_DATES+=("$current_date")
            
            # Reset for next block
            current_name="" 
        fi
    fi
done <<< "$raw_output"

# --- Check if we found anything ---
count=${#CERT_NAMES[@]}
if [ "$count" -eq 0 ]; then
    echo -e "${YELLOW}No certificates found managed by Certbot.${NC}"
    exit 0
fi

# --- Display Table ---
echo -e "${BOLD}Found $count certificates:${NC}"
printf "${BOLD}%-5s %-30s %-25s %-15s${NC}\n" "ID" "Certificate Name" "Expiry Date" "Status"
echo "-------------------------------------------------------------------------------"

today_epoch=$(date +%s)
declare -a CERT_INDICES

for (( i=0; i<count; i++ )); do
    name="${CERT_NAMES[$i]}"
    date_str="${CERT_DATES[$i]}"
    
    # Convert date to epoch for comparison
    cert_epoch=$(date -d "$date_str" +%s 2>/dev/null)
    
    # Calculate days remaining
    if [ -n "$cert_epoch" ]; then
        diff_sec=$((cert_epoch - today_epoch))
        days_left=$((diff_sec / 86400))
        
        if [ "$days_left" -lt 0 ]; then
            status_color=$RED
            status_text="EXPIRED ($((days_left * -1)) days ago)"
        elif [ "$days_left" -lt 30 ]; then
            status_color=$YELLOW
            status_text="EXPIRING ($days_left days left)"
        else
            status_color=$GREEN
            status_text="VALID ($days_left days left)"
        fi
    else
        status_color=$RED
        status_text="DATE ERROR"
    fi

    # Print Row
    printf "%-5s %-30s %-25s ${status_color}%-15s${NC}\n" "$((i+1))" "$name" "${date_str:0:10}" "$status_text"
done

echo ""

# --- User Selection ---
while true; do
    read -p "Enter the ID of the certificate to renew (or 'q' to quit): " choice
    
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        echo "Exiting."
        exit 0
    fi

    # Validate input is a number and within range
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        selected_index=$((choice - 1))
        selected_cert="${CERT_NAMES[$selected_index]}"
        break
    else
        echo -e "${RED}Invalid selection. Please enter a number between 1 and $count.${NC}"
    fi
done

# --- Confirmation & Execution ---
echo ""
echo -e "You selected: ${BOLD}${BLUE}$selected_cert${NC}"
read -p "Are you sure you want to attempt renewal for this certificate? (y/n): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Running certbot renewal for $selected_cert...${NC}"
    echo "--------------------------------------------------------"
    
    # Run the renewal command for the specific certificate
    certbot renew --cert-name "$selected_cert"
    
    echo "--------------------------------------------------------"
    echo -e "${BLUE}Process complete.${NC}"
else
    echo "Renewal cancelled."
    exit 0
fi
