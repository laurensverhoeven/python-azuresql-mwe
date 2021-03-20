# https://docs.docker.com/engine/reference/builder/

# Use an official Python runtime as a parent image
FROM python:3.9-buster

# Set the working directory to /code
RUN mkdir -p /code
WORKDIR /code
ADD . /code

# Add The repo for the MS SQL ODBC driver
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#debian17
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Install dependencies
RUN apt-get update
RUN apt-get install build-essential
RUN apt-get install -y unixodbc-dev
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17

# Install any needed packages specified in requirements.txt
RUN python3 -m pip install -r requirements.txt

# Set up Django
EXPOSE 8000

RUN python3 ./djangoazuresql/manage.py makemigrations
RUN python3 ./djangoazuresql/manage.py migrate

# RUN python3 ./djangoazuresql/manage.py runserver

# Set up init script
COPY init.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/init.sh

# Run manage.py when the container launches
# CMD ["python3", "./djangoazuresql/manage.py runserver"]
ENTRYPOINT ["init.sh"]
