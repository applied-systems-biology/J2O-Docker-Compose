# JIPipeRunner-docker (A docker-compose setup for testing JIPipeRunner)

This is an example of running OMERO.server and OMERO.web in Docker with every service 
also running that is necessary for JIPipeRunner to work. This repository can be used to test
JIPipeRunner and collect feedback from users, without a need for them to setup OMERO themselves.

OMERO.server is listening on the standard OMERO ports `4063` and `4064`.
OMERO.web is listening on port `4080` (http://localhost:4080/).

Log in as user `root` password `omero`.
The initial password can be changed in [`docker-compose.yml`](docker-compose.yml).


## Run

First pull the latest major versions of the containers:

    docker compose pull

Then start the containers:

    docker compose up