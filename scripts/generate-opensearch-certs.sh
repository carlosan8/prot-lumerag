#!/bin/sh
set -eu

apk add --no-cache openssl

if [ -s /certs/opensearch.pem ] \
    && [ -s /certs/opensearch-key.pem ] \
    && [ -s /ca/ca.pem ]; then
    exit 0
fi

openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3650 \
    -keyout /certs/ca-key.pem \
    -out /ca/ca.pem \
    -subj "/CN=OpenSearch local CA"

openssl req -newkey rsa:2048 -sha256 -nodes \
    -keyout /certs/opensearch-key.pem \
    -out /certs/opensearch.csr \
    -subj "/CN=opensearch"

cat > /tmp/opensearch.ext <<'EOF'
subjectAltName=DNS:opensearch,DNS:localhost,IP:127.0.0.1
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
EOF

openssl x509 -req -sha256 -days 825 \
    -in /certs/opensearch.csr \
    -CA /ca/ca.pem \
    -CAkey /certs/ca-key.pem \
    -CAcreateserial \
    -out /certs/opensearch.pem \
    -extfile /tmp/opensearch.ext

chown 1000:1000 /certs/opensearch-key.pem
chmod 600 /certs/opensearch-key.pem
chmod 644 /certs/opensearch.pem /ca/ca.pem
rm -f /certs/ca-key.pem /certs/opensearch.csr /certs/ca.srl /tmp/opensearch.ext
