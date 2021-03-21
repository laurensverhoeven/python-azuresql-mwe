#!/usr/bin/env bash

set -e

echo "Starting SSH ..."
service ssh start

gunicorn -b 0.0.0.0:8000 --workers=8 djangoazuresql.asgi -k uvicorn.workers.UvicornWorker
