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

OMERO=/opt/omero/server/venv3/bin/omero

# perform all OMERO‐CLI steps as omero-server user
$OMERO login -s "$OMERO_HOST:$OMERO_PORT" -u "$OMERO_USER" -w "$OMERO_PASSWORD"

$OMERO obj new Project name=CustomResults description='Example project to select for custom input'

PID=$($OMERO obj new Project name=Data description='Example project that holds data')

DID=$($OMERO obj new Dataset name=ExampleData description='Example dataset that holds data')

$OMERO obj new ProjectDatasetLink parent=$PID child=$DID

$OMERO import ExampleFiles/ExampleImage.JPG -T Dataset:name:ExampleData

OFID=$($OMERO upload ExampleFiles/DockerDemoPipeline.jip)

FAID=$($OMERO obj new FileAnnotation file=$OFID description="JIPipe demo workflow file")

$OMERO obj new ProjectAnnotationLink child=$FAID parent=$PID

OFID=$($OMERO upload ExampleFiles/DockerDemoPipeline.crate.zip)

FAID=$($OMERO obj new FileAnnotation file=$OFID description="JIPipe demo workflow RO-Crate")

$OMERO obj new ProjectAnnotationLink child=$FAID parent=$PID

SID="$($OMERO obj new Screen \
  name=ExampleHCS \
  description='Example HCS screen imported from hcs.companion.ome')"
SCREEN_ID="${SID#Screen:}"

# Real HCS import
$OMERO import ExampleFiles/plate-companion/hcs.companion.ome -r "$SCREEN_ID"

# Upload Cellpose model
OFID=$($OMERO upload ExampleFiles/Zoltan_02_Size30_allNodules_20Images_1000epochs)

FAID=$($OMERO obj new FileAnnotation file=$OFID description="Cellpose model for node detection")

$OMERO obj new ProjectAnnotationLink child=$FAID parent=$PID
