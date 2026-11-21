
#!/bin/bash
set -euo pipefail

# Get Docker base image from Dockerfile
dockerImageName=$(awk '$1=="FROM" {print $2; exit}' Dockerfile)

echo "Docker Image: $dockerImageName"

# Trivy configuration
TRIVY_IMAGE="aquasec/trivy:0.76.2"

# Create persistent cache
docker volume create trivy-cache >/dev/null

# Scan HIGH vulnerabilities (informational)
echo "=== Scanning HIGH vulnerabilities ==="
mkdir -p trivy-reports

docker run --rm \
    -v trivy-cache:/root/.cache/ \
    "$TRIVY_IMAGE" image \
    --timeout 15m \
    --scanners vuln \
    --exit-code 0 \
    --severity HIGH \
    --format table \
    "$dockerImageName" > trivy-reports/trivy-high.txt

cat trivy-reports/trivy-high.txt

# Scan CRITICAL vulnerabilities (blocking)
echo "=== Scanning CRITICAL vulnerabilities ==="
mkdir -p trivy-reports

if docker run --rm \
    -v trivy-cache:/root/.cache/ \
    "$TRIVY_IMAGE" image \
    --timeout 15m \
    --scanners vuln \
    --exit-code 1 \
    --severity CRITICAL \
    --format table \
    "$dockerImageName" > trivy-reports/trivy-critical.txt
then
    cat trivy-reports/trivy-critical.txt
    echo "Image scanning passed."
    echo "No CRITICAL vulnerabilities found."
else
    cat trivy-reports/trivy-critical.txt || true
    echo "Image scanning failed."
    echo "CRITICAL vulnerabilities or scanner error."
    exit 1
fi

echo "=== Trivy scanning completed ==="
