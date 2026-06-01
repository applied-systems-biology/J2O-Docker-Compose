#!/bin/bash

READY_FILE="/opt/omero/web/OMERO.web/etc/grid/j2o-config-ready"
rm -f "$READY_FILE"

# Wait for OMERO.server to be available
echo "Waiting for OMERO.server at omeroserver:4064..."
for i in {1..30}; do
  (echo > /dev/tcp/omeroserver/4064) &>/dev/null && break
  echo "Still waiting... ($i)"
  sleep 2
done

# Ensure directories exist with world-write permissions
mkdir -p /opt/omero/web/OMERO.web/var/j2o-files/data
mkdir -p /opt/omero/web/OMERO.web/var/j2o-files/logs
chmod 777 /opt/omero/web/OMERO.web/var/j2o-files/data
chmod 777 /opt/omero/web/OMERO.web/var/j2o-files/logs

echo "OMERO.server is available."

# Basic OMERO.web setup
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.server_list '[ [\"omeroserver\", 4064] ]'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.static_url '/static/'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.jipipe.tempdir '/opt/omero/web/OMERO.web/var/j2o-files/data'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.jipipe.logdir '/opt/omero/web/OMERO.web/var/j2o-files/logs'"
# Collect static files
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero web syncmedia"

# Set to debug mode
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.debug True"

# Plugin setup
existing_apps=$(su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config get omero.web.apps")
if [[ "$existing_apps" != *"J2O"* ]]; then
        su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config append omero.web.apps '\"J2O\"'"
        su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config append omero.web.ui.right_plugins '[\"J2O\", \"J2O/right_plugin_example.js.html\", \"jipipe_form_container\"]'"
fi
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.imagej \"/opt/Fiji.app/ImageJ-linux64\""

# Redis cache config
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.caches '{\"default\": {\"BACKEND\": \"django_redis.cache.RedisCache\", \"LOCATION\": \"redis://redis:6379/0\"}}'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.session_engine 'django.contrib.sessions.backends.cache'"

# GPU acceleration setup
if [ "${ENABLE_NVIDIA_GPU:-0}" = "1" ]; then
    echo "ENABLE_NVIDIA_GPU=1; Setting gpu_devices to all in OMERO config..."
    su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.jipipe.gpu_devices 'nvidia.com/gpu=all'"
else
    echo "ENABLE_NVIDIA_GPU=0; Setting gpu_devices to none in OMERO config..."
    su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.jipipe.gpu_devices ''"
fi

echo "J2O config initialized."
touch "$READY_FILE"

# Start OMERO.web
exec su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero web start --foreground"
