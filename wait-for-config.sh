#!/usr/bin/env bash
set -euo pipefail

: "${OMERODIR:?OMERODIR environment variable not defined}"

CONFIG_FILE="${OMERODIR}/etc/grid/config.xml"
READY_FILE="${OMERODIR}/etc/grid/j2o-config-ready"

echo "Waiting for OMERO.web config initialization..."
echo "Config file: ${CONFIG_FILE}"
echo "Ready marker: ${READY_FILE}"

for i in {1..60}; do
    config_exists=0
    caches_ready=0
    j2o_ready=0

    if [ -f "$CONFIG_FILE" ]; then
        config_exists=1

        if grep -q "omero.web.caches" "$CONFIG_FILE"; then
            caches_ready=1
        fi
    fi

    if [ -f "$READY_FILE" ]; then
        j2o_ready=1
    fi

    if [ "$config_exists" -eq 1 ] && [ "$caches_ready" -eq 1 ] && [ "$j2o_ready" -eq 1 ]; then
        echo "OMERO.web config is ready."
        echo "Found omero.web.caches."
        echo "Found J2O readiness marker."
        exec "$@"
    fi

    echo "Waiting... ($i/60) config_exists=${config_exists} caches_ready=${caches_ready} j2o_ready=${j2o_ready}"
    sleep 2
done

echo "Timeout waiting for OMERO.web/J2O config initialization."

echo "Final status:"
if [ -f "$CONFIG_FILE" ]; then
    echo "  config.xml exists: yes"
    if grep -q "omero.web.caches" "$CONFIG_FILE"; then
        echo "  omero.web.caches present: yes"
    else
        echo "  omero.web.caches present: no"
    fi
else
    echo "  config.xml exists: no"
fi

if [ -f "$READY_FILE" ]; then
    echo "  j2o-config-ready exists: yes"
else
    echo "  j2o-config-ready exists: no"
fi

exit 1
