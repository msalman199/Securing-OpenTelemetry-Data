#!/bin/bash

# Flush existing rules
sudo iptables -F
sudo iptables -X

# Set default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback traffic
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (adjust port if needed)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow OpenTelemetry ports only from localhost and specific networks
# OTLP gRPC port (4317)
sudo iptables -A INPUT -p tcp --dport 4317 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 4317 -s 10.0.0.0/8 -j ACCEPT

# OTLP HTTP port (4318)
sudo iptables -A INPUT -p tcp --dport 4318 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 4318 -s 10.0.0.0/8 -j ACCEPT

# Allow metrics endpoint (8888) only from localhost
sudo iptables -A INPUT -p tcp --dport 8888 -s 127.0.0.1 -j ACCEPT

# Log dropped packets
sudo iptables -A INPUT -j LOG --log-prefix "DROPPED: "

# Save rules (Ubuntu/Debian)
sudo iptables-save > /etc/iptables/rules.v4

echo "Firewall rules configured for OpenTelemetry security"
