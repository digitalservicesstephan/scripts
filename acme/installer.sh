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
    if [ -f "/etc/pve/pve.conf" ] && [ -d "/usr/share/proxmox-acme" ]; then
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

# Perform system checks before proceeding
echo "Checking system requirements..."
check_requirements

# Detect and validate environment
echo "Detecting environment..."
IS_PROXMOX=false
detect_environment

# Configuration
if [ "$IS_PROXMOX" = true ]; then
    DNSAPI_DIR="/usr/share/proxmox-acme/dnsapi"
    CONFIG_DIR="/etc/proxmox-acme"
else
    ACME_INSTALL_DIR="/root/.acme.sh"
    DNSAPI_DIR="${ACME_INSTALL_DIR}/dnsapi"
    CONFIG_DIR="${ACME_INSTALL_DIR}"
fi

# Install dependencies
command -v jq >/dev/null 2>&1 || { echo "Installing jq..."; apt-get update && apt-get install -y jq; }

# Install acme.sh if not already installed
if [ ! -f "${ACME_INSTALL_DIR}/acme.sh" ]; then
    echo "Installing acme.sh..."
    curl https://get.acme.sh | sh -s email=admin@yourdomain.com
else
    echo "acme.sh is already installed"
fi

# Create directories if they don't exist
mkdir -p "${DNSAPI_DIR}"
[ "$IS_PROXMOX" = true ] && mkdir -p "${CONFIG_DIR}"

# Download the DNS API script from GitHub
echo "Downloading DSS DNS API script..."
curl -s -o "${DNSAPI_DIR}/dns_dss.sh" \
    "https://raw.githubusercontent.com/digitalservicesstephan/scripts/main/acme/dns_dss.sh"
chmod +x "${DNSAPI_DIR}/dns_dss.sh"

# Configuration wizard
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
if [ "$IS_PROXMOX" = true ]; then
    echo "export DSS_API_KEY='${api_key}'" > "${CONFIG_DIR}/dss_credentials.sh"
    chmod 600 "${CONFIG_DIR}/dss_credentials.sh"
    # Add source line to plugin if not already present
    if ! grep -q "source.*dss_credentials.sh" "${DNSAPI_DIR}/dns_dss.sh"; then
        sed -i '2i# Source credentials\n[ -f "/etc/proxmox-acme/dss_credentials.sh" ] && source "/etc/proxmox-acme/dss_credentials.sh"' "${DNSAPI_DIR}/dns_dss.sh"
    fi
else
    echo "export DSS_API_KEY='${api_key}'" >> "${CONFIG_DIR}/account.conf"
fi

echo
echo "Installation complete!"
echo "====================="
if [ "$IS_PROXMOX" = true ]; then
    echo "The DSS DNS API integration has been installed for Proxmox ACME."
    echo
    echo "You can now use it in the Proxmox web interface by selecting"
    echo "'DSS DNS' as your DNS plugin."
else
    echo "The DSS DNS API integration has been installed for acme.sh."
    echo
    echo "You can now use it with acme.sh by adding --dns dns_dss"
    echo "Example: acme.sh --issue -d example.com --dns dns_dss"
fi
