#!/bin/bash
set -e

echo "================================================"
echo "NidanEHR Superset Metadata Initialization"
echo "================================================"

# Run the Python metadata initialization script
echo "Running metadata initialization..."
python3 /app/pythonpath/init_superset_metadata.py || true

echo "================================================"
echo "Metadata initialization complete!"
echo "================================================"
