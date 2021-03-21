# Django Azure SQL MWE

## Introduction 
Minimal working example for testing Azure SQL connectivity in Django.

## Getting Started
1.	Install dependencies and set up

Install dependencies:

    sudo apt update
    sudo apt install -y python3 python3-venv python3-pip
    sudo python3 -m pip install virtualenv virtualenvwrapper

Install the MS SQL odbc driver:
( https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#ubuntu17 )

    sudo bash -c "curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -"
    sudo bash -c "curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list"

    sudo apt-get update
    sudo ACCEPT_EULA=Y apt-get -y install msodbcsql17
    sudo apt-get install -y unixodbc-dev

Set up environment variables for virtualenv:

    echo 'export VIRTUALENVWRAPPER_PYTHON='/usr/bin/python3'' >> "${HOME}/.bashrc"
    echo "export WORKON_HOME=${HOME}/.virtualenvs" >> "${HOME}/.bashrc"
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> "${HOME}/.bashrc"
    source "${HOME}/.bashrc"

Create the virtualenv, copy the .env file and install the python packages:

    cd python-azuresql-mwe
    mkvirtualenv azure-sql-mwe
    python3 -m pip install -r requirements.txt

2. Set up the Azure SQL db

Install the Azure-cli tooling:

    sudo apt remove azure-cli -y && sudo apt autoremove -y # Uninstall the version from the default repo
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
    sudo apt-get update
    sudo apt-get install -y azure-cli

Add your proxy's certificate to Azure-cli's cacert bundle (if you are behind a corporate proxy):

    sudo cp /opt/az/lib/python3.6/site-packages/certifi/cacert.pem /opt/az/lib/python3.6/site-packages/certifi/cacert.pem.original
    echo -e "# My Proxy Proxy Cert\n# Installed on $(date +'%Y-%m-%d')" > /tmp/my_proxy_cert.pem
    cat "${path_to_proxy_cert}" >> /tmp/my_proxy_cert.pem
    sudo bash -c "cat /tmp/my_proxy_cert.pem >> /opt/az/lib/python3.6/site-packages/certifi/cacert.pem"

Log in to Azure with az:

    subscription_id="ID_OF_YOUR_SUBSCRIPTION"

    az login
    az account set -s "${subscription_id}"

Create the Azure SQL DB:
( https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-cli )

    resource_group="django-azure-sql"
    azure_sql_server_name="django-azure-sql-server"
    azure_sql_db_name="django-azure-sql-db"
    azure_sql_admin_user="django-admin"
    azure_sql_admin_password="PASSWORD"
    
    location="westeurope"
    external_ip=$(curl -s http://whatismyip.akamai.com/)
    startIP="${external_ip}"
    endIP="${external_ip}"

    az group create --name "${resource_group}" --location "${location}"

    az sql server create --name "${azure_sql_server_name}" --resource-group "${resource_group}" --location "${location}" --admin-user "${azure_sql_admin_user}" --admin-password "${azure_sql_admin_password}"

    az sql server firewall-rule create --resource-group "${resource_group}" --server "${azure_sql_server_name}" -n AllowYourIp --start-ip-address "${startIP}" --end-ip-address "${endIP}"

    az sql db create --resource-group "${resource_group}" --server "${azure_sql_server_name}" --name "${azure_sql_db_name}" --edition Basic --zone-redundant false


Create a .env file with the configuration of your Azure SQL db:

    cp .env.example .env
    nano .env

In this file, update the variables to have the correct values:

    AZURE_AZURE_SQL_DATABASE="DBNAME"
    AZURE_SQL_USER="USERNAME"
    AZURE_SQL_PASSWORD="PASSWORD"
    AZURE_SQL_HOST="domain.com"
    AZURE_SQL_PORT="1433"
    AZURE_SQL_DRIVER="ODBC Driver 17 for SQL Server"

Initialize the database:

    workon azure-sql-mwe
    python3 ./djangoazuresql/manage.py makemigrations
    python3 ./djangoazuresql/manage.py migrate

3. Run the application locally

Run the application using the following commands:

    workon azure-sql-mwe
    python3 ./djangoazuresql/manage.py runserver

Navigate to http://127.0.0.1:8000

4. Deploy to Azure

Create a app_settings.json file with the configuration of your Azure SQL db:

    cp app_settings-example.json app_settings.json
    nano app_settings.json

In this file, update the variables to have the correct values:

    DBNAME="DBNAME"
    DBUSER="USERNAME"
    DBPASS="PASSWORD"
    DBHOST="domain.com"

Publish the Web App:
    
    resource_group="django-azure-sql"
    web_app_name="django-azure-sql-webapp"
    location="westeurope"

    az webapp up --resource-group "${resource_group}" --sku B1 --name "${web_app_name}" --location "${location}"
    az webapp config appsettings set --settings @app_settings.json

SSH into the webapp: open https://django-azure-sq-webapp.scm.azurewebsites.net/webssh/host or do:

    az webapp ssh 
