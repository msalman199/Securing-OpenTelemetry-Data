#!/bin/bash

LOG_DIR="/var/log/otel-security"
DATA_DIR="$HOME/otel-security/data"

# Create log directory
sudo mkdir -p $LOG_DIR
sudo chown $USER:$USER $LOG_DIR

# Function to check certificate expiration
check_cert_expiration() {
    local cert_file=$1
    local days_until_expiry=$(openssl x509 -in "$cert_file" -noout -checkend $((30*24*3600)) && echo "OK" || echo "EXPIRING")
    
    if [ "$days_until_expiry" = "EXPIRING" ]; then
        echo "$(date): WARNING - Certificate $cert_file expires within 30 days" >> $LOG_DIR/security.log
    fi
}

# Function to monitor failed connections
monitor_connections() {
    local failed_connections=$(grep "connection refused\|handshake failure" $DATA_DIR/*.json 2>/dev/null | wc -l)
    
    if [ $failed_connections -gt 10 ]; then
        echo "$(date): ALERT - High number of failed connections detected: $failed_connections" >> $LOG_DIR/security.log
    fi
}

# Function to check for suspicious patterns
check_suspicious_activity() {
    local suspicious_patterns=("sql injection" "script injection" "path traversal" "buffer overflow")
    
    for pattern in "${suspicious_patterns[@]}"; do
        local count=$(grep -i "$pattern" $DATA_DIR/*.json 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            echo "$(date): SECURITY ALERT - Suspicious pattern detected: $pattern (count: $count)" >> $LOG_DIR/security.log
        fi
    done
}

# Main monitoring loop
while true; do
    # Check certificate expiration
    check_cert_expiration "$HOME/otel-security/certs/server-cert.pem"
    check_cert_expiration "$HOME/otel-security/certs/client-cert.pem"
    
    # Monitor connections
    monitor_connections
    
    # Check for suspicious activity
    check_suspicious_activity
    
    # Sleep for 5 minutes
    sleep 300
done
