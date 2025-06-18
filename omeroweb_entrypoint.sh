#!/bin/bash

# Wait for OMERO.server to be available
echo "Waiting for OMERO.server at omeroserver:4064..."
for i in {1..30}; do
  (echo > /dev/tcp/omeroserver/4064) &>/dev/null && break
  echo "Still waiting... ($i)"
  sleep 2
done

echo "OMERO.server is available."

# Basic OMERO.web setup
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.server_list '[ [\"omeroserver\", 4064] ]'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.static_url '/static/'"

# Collect static files
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero web syncmedia"

# Set to debug mode
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.debug True"

# Plugin setup
existing_apps=$(su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config get omero.web.apps")
if [[ "$existing_apps" != *"JIPipeRunner"* ]]; then
        su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config append omero.web.apps '\"JIPipeRunner\"'"
        su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config append omero.web.ui.right_plugins '[\"JIPipeRunner\", \"JIPipeRunner/right_plugin_example.js.html\", \"jipipe_form_container\"]'"
fi
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.imagej \"/opt/Fiji.app/ImageJ-linux64\""

# Redis cache config
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.caches '{\"default\": {\"BACKEND\": \"django_redis.cache.RedisCache\", \"LOCATION\": \"redis://redis:6379/0\"}}'"
su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero config set omero.web.session_engine 'django.contrib.sessions.backends.cache'"

# Start OMERO.web
exec su -s /bin/bash omero-web -c "/opt/omero/web/venv3/bin/omero web start --foreground"
