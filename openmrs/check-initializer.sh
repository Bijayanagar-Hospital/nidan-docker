#!/bin/bash
# Run inside openmrs-backend container to diagnose Initializer/metadata loading issues.
# Usage: docker exec -it nidan-openmrs-backend /openmrs/check-initializer.sh

set -e
DATA_DIR="${OMRS_DATA_DIR:-/openmrs/data}"

echo "=== OpenMRS Initializer Diagnostic ==="
echo "Data directory: $DATA_DIR"
echo ""

echo "1. Configuration directory:"
if [ -d "$DATA_DIR/configuration" ]; then
  echo "   EXISTS - $(find "$DATA_DIR/configuration" -type f | wc -l) files"
  ls -la "$DATA_DIR/configuration" | head -20
else
  echo "   MISSING - Initializer will not load metadata!"
fi
echo ""

echo "2. Configuration checksums:"
if [ -d "$DATA_DIR/configuration_checksums" ]; then
  echo "   EXISTS - $(find "$DATA_DIR/configuration_checksums" -type f | wc -l) checksum files"
else
  echo "   (none yet - first run)"
fi
echo ""

echo "3. Property files in data dir:"
ls -la "$DATA_DIR"/*.properties 2>/dev/null || echo "   (none)"
echo ""

echo "4. Distribution openmrs_config:"
if [ -d /openmrs/distribution/openmrs_config ]; then
  echo "   EXISTS - $(find /openmrs/distribution/openmrs_config -type f | wc -l) files"
else
  echo "   MISSING"
fi
