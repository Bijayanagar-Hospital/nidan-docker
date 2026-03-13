#!/bin/bash
# Diagnostic script for Initializer metadata loading issues.
# Run from nidan-docker: ./openmrs/scripts/check-initializer.sh

set -e
CONTAINER="${1:-nidan-openmrs-backend}"

echo "=== OpenMRS Initializer Diagnostic ==="
echo "Container: $CONTAINER"
echo ""

echo "1. Config in image (distribution):"
docker run --rm --entrypoint ls nidan-docker-openmrs-backend -la /openmrs/distribution/openmrs_config 2>/dev/null || echo "   (run 'docker run --rm nidan-docker-openmrs-backend ls -la /openmrs/distribution/openmrs_config')"
echo ""

echo "2. Config at runtime (data directory - where Initializer reads from):"
docker exec "$CONTAINER" ls -la /openmrs/data/configuration/ 2>/dev/null || echo "   Container not running or path missing"
echo ""

echo "3. Configuration domains present:"
docker exec "$CONTAINER" find /openmrs/data/configuration -maxdepth 2 -type d 2>/dev/null | head -40 || true
echo ""

echo "4. Initializer-related log lines (last 50):"
docker logs "$CONTAINER" 2>&1 | grep -i initializer | tail -50 || echo "   No Initializer log lines found"
echo ""

echo "5. Any errors in recent logs:"
docker logs "$CONTAINER" 2>&1 | grep -iE "error|exception|failed" | tail -20 || echo "   No obvious errors"
echo ""

echo "6. Sample metadata check (locations count):"
docker exec "$CONTAINER" curl -s -u admin:Admin123 "http://localhost:8080/openmrs/ws/rest/v1/location?v=default" 2>/dev/null | head -c 500 || echo "   (OpenMRS may not be ready or auth may differ)"
echo ""
echo ""
echo "=== Next steps ==="
echo "- If config is empty at runtime: startup-init.sh may not have run; check container logs"
echo "- If Initializer logs show errors: fix the failing domain (e.g. remove appointment configs if module absent)"
echo "- Try fresh install: docker-compose down -v && docker-compose up -d openmrs-backend"
echo "- Try local content build: docker-compose -f docker-compose.yml -f docker-compose.openmrs-local-content.yml build openmrs-backend"
