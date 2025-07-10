#!/usr/bin/with-contenv bashio

CONFIG="/etc/ddclient/ddclient.conf"

HOST_IP=$(curl -s -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/network/info | grep -o '"address":"[0-9][^"]*' | cut -d'"' -f4 | grep -v "127.0.0.1" | head -n1)

DDCLIENT_CONFIG=$(bashio::config 'config')

bashio::log.info "Using IP: $HOST_IP"
# Process each JSON object in the config
echo "$DDCLIENT_CONFIG" | while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    
    # Parse the JSON and create config section
    zone=$(echo "$line" | jq -r '.zone')
    token=$(echo "$line" | jq -r '.token')
    domains=$(echo "$line" | jq -r '.domains')
    
    # Append configuration section for this entry
    cat >> "$CONFIG" << EOL
protocol=cloudflare
use=ip, ip=$HOST_IP
zone=${zone}
ttl=1
login=token
password=${token}
${domains}
EOL
done

# Start ddclient
ddclient -foreground -verbose -debug
