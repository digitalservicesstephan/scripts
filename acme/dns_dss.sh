#!/bin/bash

# DSS ACME DNS API integration script
# This script is used with acme.sh for DNS-01 challenge validation

# Required environment variables:
# export DSS_API_KEY="your_api_key"

# API Configuration
API_ENDPOINT="https://panel.digitalservicesstephan.de/api/v1"

# Helper Functions
_get_zone_id() {
    local domain="$1"
    local response
    
    response=$(curl -s -X GET \
        -H "Authorization: ApiKey ${DSS_API_KEY}" \
        "${API_ENDPOINT}/dns")
    
    echo "$response" | jq -r ".zones[] | select(.name == \"${domain}.\") | .id"
}

_add_txt_record() {
    local zone_id="$1"
    local name="$2"
    local value="$3"
    
    curl -s -X POST \
        -H "Authorization: ApiKey ${DSS_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"${name}.\",\"type\":\"TXT\",\"content\":\"${value}\",\"ttl\":60}" \
        "${API_ENDPOINT}/dns/${zone_id}/records"
}

_remove_txt_record() {
    local zone_id="$1"
    local name="$2"
    
    curl -s -X DELETE \
        -H "Authorization: ApiKey ${DSS_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"TXT\",\"name\":\"${name}.\"}" \
        "${API_ENDPOINT}/dns/${zone_id}/records"
}

# Main ACME DNS API Functions

# Usage: dns_dss_add _acme-challenge.www.domain.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_dss_add() {
    local full_domain="${1}"
    local txt_value="${2}"
    
    # Extract the base domain
    local domain
    domain=$(echo "${full_domain}" | awk -F. 'NF>=2{print $(NF-1)"."$NF}')
    
    # Get the zone ID
    local zone_id
    zone_id=$(_get_zone_id "${domain}")
    
    if [ -z "${zone_id}" ]; then
        echo "Error: Could not find zone ID for domain ${domain}"
        return 1
    fi
    
    # Add TXT record
    local response
    response=$(_add_txt_record "${zone_id}" "${full_domain}" "\\\"${txt_value}\\\"")

    if echo "${response}" | grep -q "error"; then
        echo "Error adding TXT record: ${response}"
        return 1
    fi
    
    # Allow time for DNS propagation
    echo "Waiting 30 seconds for DNS propagation..."
    sleep 30
    
    return 0
}

# Usage: dns_dss_rm _acme-challenge.www.domain.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_dss_rm() {
    local full_domain="${1}"
    
    # Extract the base domain
    local domain
    domain=$(echo "${full_domain}" | awk -F. 'NF>=2{print $(NF-1)"."$NF}')
    
    # Get the zone ID
    local zone_id
    zone_id=$(_get_zone_id "${domain}")
    
    if [ -z "${zone_id}" ]; then
        echo "Error: Could not find zone ID for domain ${domain}"
        return 1
    fi
    
    # Remove TXT record
    local response
    response=$(_remove_txt_record "${zone_id}" "${full_domain}")
    
    echo "API Response for removing TXT record: ${response}"
    
    if echo "${response}" | grep -q "error"; then
        echo "Error removing TXT record: ${response}"
        return 1
    fi
    
    return 0
}

# Export the functions for acme.sh
ACME_DNS_API="dns_dss"
