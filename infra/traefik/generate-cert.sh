#!/bin/sh
set -eu
apk add --no-cache openssl >/dev/null
if [ ! -s /certs/tls.crt ] || [ ! -s /certs/tls.key ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 365 \
    -keyout /certs/tls.key -out /certs/tls.crt \
    -subj "/CN=hospital.lab/O=Hospital Lab/OU=Secure Legacy" \
    -addext "subjectAltName=DNS:hospital.lab,DNS:*.hospital.lab"
  chmod 600 /certs/tls.key
fi
cat > /dynamic/local-tls.yml <<'EOF'
tls:
  certificates:
    - certFile: /certs/tls.crt
      keyFile: /certs/tls.key
EOF
