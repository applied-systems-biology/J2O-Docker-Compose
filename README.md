# J2O-Docker-Compose (A docker-compose setup for testing JIPipe 2 OMERO)

This is an example of running OMERO.server and OMERO.web in Docker with every service 
also running that is necessary for J2O to work. This repository can be used to test
J2O and collect feedback from users, without a need for them to setup OMERO themselves.

OMERO.server is listening on the standard OMERO ports `4063` and `4064`.
OMERO.web is listening on port `4080` (http://localhost:4080/).

Log in as user `root` password `omero`.
The initial password can be changed in [`docker-compose.yml`](docker-compose.yml).


## Run

First, clone the repository and navigate to the folder:

    git clone https://github.com/applied-systems-biology/J2O-Docker-Compose.git
    cd J2O-Docker-Compose


Then, pull the latest major versions of the containers:

    docker compose pull

Finally, start the containers:

    docker compose up
