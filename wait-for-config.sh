#!/bin/bash
set -e

echo "Waiting for config.xml to contain omero.web.caches..."
CONFIG_FILE="$OMERODIR/etc/grid/config.xml"

for i in {1..30}; do
  if grep -q "omero.web.caches" "$CONFIG_FILE"; then
    echo "Found omero.web.caches."
    exec "$@"
  fi
  echo "Waiting... ($i)"
  sleep 2
done

echo "Timeout waiting for omero.web.caches in config.xml"
exit 1
