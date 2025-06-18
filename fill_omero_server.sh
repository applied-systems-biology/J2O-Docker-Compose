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
