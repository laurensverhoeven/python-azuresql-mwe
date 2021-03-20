#!/usr/bin/env bash

cd  /code/djangoazuresql/

gunicorn -b 0.0.0.0:8000 --workers=8 djangoazuresql.asgi -k uvicorn.workers.UvicornWorker
