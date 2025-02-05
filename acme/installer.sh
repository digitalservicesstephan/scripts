#!/bin/bash

# DSS ACME DNS API installer
# This script installs the DSS DNS API integration for acme.sh

set -e

# Function to check system requirements
check_requirements() {
    # Check if running on Linux
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Error: This installer only supports Linux systems" 1>&2
        exit 1
    fi

    # Check if running as root
    if [ "$(id -u)" != "0" ]; then
        echo "Error: This script must be run as root" 1>&2
        exit 1
    fi

    # Check for required commands
    for cmd in curl grep sed mkdir chmod jq; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo "Error: Required command '$cmd' not found" 1>&2
            echo "Please install the required dependencies first:" 1>&2
            echo "  - curl: for downloading files" 1>&2
            echo "  - jq: for JSON processing" 1>&2
            echo "  - grep, sed, mkdir, chmod: for basic file operations" 1>&2
            exit 1
        fi
    done
}

# Function to detect environment
detect_environment() {
    local env_found=false

    # Check for Proxmox VE
    if [ -d "/usr/share/proxmox-acme" ]; then
        echo "Detected Proxmox VE environment"
        IS_PROXMOX=true
        env_found=true
    fi

    # Check for acme.sh
    if command -v acme.sh >/dev/null 2>&1 || [ -f "/root/.acme.sh/acme.sh" ]; then
        echo "Detected acme.sh installation"
        env_found=true
    fi

    if [ "$env_found" = false ]; then
        echo "Error: Neither Proxmox VE nor acme.sh found" 1>&2
        echo "Please install acme.sh first: https://github.com/acmesh-official/acme.sh" 1>&2
        exit 1
    fi
}

# Function to update Proxmox schema
update_proxmox_schema() {
    local schema_file="/usr/share/proxmox-acme/dns-challenge-schema.json"
    if [ ! -f "$schema_file" ]; then
        echo "Error: Proxmox ACME schema file not found" 1>&2
        exit 1
    fi

    # Create a temporary file
    local temp_file=$(mktemp)

    # Add DSS plugin to schema if not already present
    jq '. + {
        "dss": {
            "fields": {
                "DSS_API_KEY": {
                    "description": "DSS API Key for DNS authentication",
                    "type": "string"
                }
            },
            "name": "DSS DNS"
        }
    }' "$schema_file" > "$temp_file"

    # Check if jq command was successful
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$schema_file"
        chmod 644 "$schema_file"
    else
        rm "$temp_file"
        echo "Error: Failed to update Proxmox schema file" 1>&2
        exit 1
    fi
}

# Perform system checks before proceeding
echo "Checking system requirements..."
check_requirements

# Detect and validate environment
echo "Detecting environment..."
IS_PROXMOX=false
detect_environment

# Set installation directories based on environment
if [ "$IS_PROXMOX" = true ]; then
    DNSAPI_DIR="/usr/share/proxmox-acme/dnsapi"
else
    ACME_INSTALL_DIR="/root/.acme.sh"
    DNSAPI_DIR="${ACME_INSTALL_DIR}/dnsapi"
fi

# Install dependencies
command -v jq >/dev/null 2>&1 || { echo "Installing jq..."; apt-get update && apt-get install -y jq; }

# Create directories if they don't exist
mkdir -p "${DNSAPI_DIR}"

# Download the DNS API script from GitHub
echo "Downloading DSS DNS API script..."
curl -s -o "${DNSAPI_DIR}/dns_dss.sh" \
    "https://raw.githubusercontent.com/digitalservicesstephan/scripts/main/acme/dns_dss.sh"
chmod +x "${DNSAPI_DIR}/dns_dss.sh"

# Update Proxmox schema if in Proxmox environment
if [ "$IS_PROXMOX" = true ]; then
    echo "Updating Proxmox ACME schema..."
    update_proxmox_schema
fi

echo
echo "Installation complete!"
echo "====================="

if [ "$IS_PROXMOX" = true ]; then
    echo "The DSS DNS API integration has been installed for Proxmox ACME."
    echo
    echo "Please configure your DSS API key through the Proxmox web interface:"
    echo "1. Navigate to Datacenter -> ACME"
    echo "2. Select 'Plugin' -> 'DSS DNS'"
    echo "3. Enter your API key in the configuration"
else
    # Configuration wizard for standalone acme.sh
    echo "DSS ACME Configuration"
    echo "=========================="
    echo

    # Get API key
    read -p "Enter your DSS API key: " api_key
    while [ -z "${api_key}" ]; do
        echo "API key cannot be empty"
        read -p "Enter your DSS Panel API key: " api_key
    done

    # Save the API key
    echo "export DSS_API_KEY='${api_key}'" >> "${ACME_INSTALL_DIR}/account.conf"

    echo "The DSS DNS API integration has been installed for acme.sh."
    echo
    echo "You can now use it with acme.sh by adding --dns dns_dss"
    echo "Example: acme.sh --issue -d example.com --dns dns_dss"
fi
