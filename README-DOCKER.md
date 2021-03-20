# docker-pyodbc

## Introduction
Docker image with pyodbc installed

## Getting Started

1. Build

Build the docker image:

    cd python-azuresql-mwe/
    docker build -t python-azuresql-mwe:Dockerfile .

2.	Run

Stop and delete my-pyodbc-image, if needed:

    docker stop python-azuresql-mwe; docker rm python-azuresql-mwe

Run the new docker image:

    docker run -p 8000:8000 --name python-azuresql-mwe python-azuresql-mwe:Dockerfile

    # docker run -p 8000:8000 -dit --name python-azuresql-mwe python-azuresql-mwe:Dockerfile
    #docker exec -i -t python-azuresql-mwe /bin/bash

2.	Push to Hub

Push the docker to Docker Hub:

    docker commit -m "Created python-azuresql-mwe container," -a "python-azuresql-mwe" python-azuresql-mwe USER/python-azuresql-mwe:latest
    docker push USER/python-azuresql-mwe
