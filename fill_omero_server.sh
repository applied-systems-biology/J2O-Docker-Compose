#!/usr/bin/env bash
set -e

echo "Waiting for OMERO server to be ready..."
for i in {1..15}; do
  if /opt/omero/server/venv3/bin/omero login -s "$OMERO_HOST:$OMERO_PORT" -u "$OMERO_USER" -w "$OMERO_PASSWORD" &>/dev/null; then
    echo "OMERO server is ready!"
    break
  fi
  echo "OMERO not ready yet (attempt $i)..."
  sleep 5
done

echo "Checking if any Project exists..."

RAW_PROJECT_COUNT_OUTPUT=$(
  /opt/omero/server/venv3/bin/omero hql \
    "select count(p.id) from Project p" 2>&1
)

echo "$RAW_PROJECT_COUNT_OUTPUT"

PROJECT_COUNT=$(
  echo "$RAW_PROJECT_COUNT_OUTPUT" |
  awk -F'|' '
    $1 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      if ($2 ~ /^[0-9]+$/) print $2
    }
  ' |
  head -n 1
)

if [ -z "$PROJECT_COUNT" ]; then
  echo "Could not parse Project count. Refusing to populate to avoid duplicates."
  exit 1
fi

echo "Found $PROJECT_COUNT project(s)."

if [ "$PROJECT_COUNT" -gt 0 ]; then
  echo "At least one project exists. Skipping population."
  exit 0
fi

# perform all OMERO‐CLI steps as omero-server user
/opt/omero/server/venv3/bin/omero login -s "$OMERO_HOST:$OMERO_PORT" -u "$OMERO_USER" -w "$OMERO_PASSWORD"

/opt/omero/server/venv3/bin/omero obj new Project name=CustomResults description='Example project to select for custom input'

PID=$(/opt/omero/server/venv3/bin/omero obj new Project name=Data description='Example project that holds data')

DID=$(/opt/omero/server/venv3/bin/omero obj new Dataset name=ExampleData description='Example dataset that holds data')

/opt/omero/server/venv3/bin/omero obj new ProjectDatasetLink parent=$PID child=$DID

/opt/omero/server/venv3/bin/omero import ExampleFiles/ExampleImage.png -T Dataset:name:ExampleData

OFID=$(/opt/omero/server/venv3/bin/omero upload ExampleFiles/DockerDemoPipeline.jip)

FAID=$(/opt/omero/server/venv3/bin/omero obj new FileAnnotation file=$OFID description="JIPipe pipeline file")

/opt/omero/server/venv3/bin/omero obj new ProjectAnnotationLink child=$FAID parent=$PID
