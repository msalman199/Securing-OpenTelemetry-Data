#!/bin/bash

echo "=== OpenTelemetry Security Test ==="

# Test 1: Certificate validation
echo "1. Testing certificate validation..."
openssl verify -CAfile certs/ca.pem certs/server-cert.pem
openssl verify -CAfile certs/ca.pem certs/client-cert.pem

# Test 2: TLS connection
echo "2. Testing TLS connection..."
timeout 5 openssl s_client -connect localhost:4317 -cert certs/client-cert.pem -key certs/client-key.pem -CAfile certs/ca.pem -verify_return_error < /dev/null

# Test 3: Data encryption verification
echo "3. Checking data encryption..."
if [ -f "data/encrypted-traces.json" ]; then
    echo "Encrypted data file exists"
    echo "File size: $(stat -c%s data/encrypted-traces.json) bytes"
    echo "Sample encrypted content:"
    head -5 data/encrypted-traces.json
else
    echo "No encrypted data file found"
fi

# Test 4: Security monitoring
echo "4. Checking security monitoring..."
if [ -f "/var/log/otel-security/security.log" ]; then
    echo "Security log exists"
    tail -5 /var/log/otel-security/security.log
else
    echo "Security monitoring not active"
fi

echo "=== Security Test Complete ==="
