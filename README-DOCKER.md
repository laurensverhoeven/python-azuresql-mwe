# docker-pyodbc

## Introduction
Docker image with pyodbc installed

## Getting Started

### Build

Build the docker image:

```bash
cd python-azuresql-mwe/
docker build -t python-azuresql-mwe:Dockerfile .
```

### Run

Stop and delete my-pyodbc-image, if needed:

```bash
docker stop python-azuresql-mwe; docker rm python-azuresql-mwe
```

Run the new docker image:

```bash
docker run -p 8000:8000 --name python-azuresql-mwe python-azuresql-mwe:Dockerfile

# docker run -p 8000:8000 -dit --name python-azuresql-mwe python-azuresql-mwe:Dockerfile
# docker exec -i -t python-azuresql-mwe /bin/bash
```

Go to:

    http://127.0.0.1:8000/


### Push to Hub

Push the docker to Docker Hub:

```bash
docker commit -m "Created python-azuresql-mwe container," -a "python-azuresql-mwe" python-azuresql-mwe USER/python-azuresql-mwe:latest
docker push USER/python-azuresql-mwe
```


### Deploy to Azure App Service

Install the Azure-cli tooling:

```bash
sudo apt remove azure-cli -y && sudo apt autoremove -y # Uninstall the version from the default repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install -y azure-cli
```


Install jq:

```bash
sudo apt-get install -y jq
```


Log in to Azure with az:

```bash
subscription_id="ID_OF_YOUR_SUBSCRIPTION"

az login
az account set -s "${subscription_id}"
```


Create the Azure SQL DB:
( https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-cli )

```bash
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
```

Push the image to Azure Container Registry

```bash
acr_name="djangoazuresqlacr"
docker_image_tag="python-azuresql-mwe"

az acr create --name "${acr_name}" --resource-group "${resource_group}" --sku Basic --admin-enabled true

acr_password="$(az acr credential show --resource-group "${resource_group}" --name "${acr_name}" | jq -r '.passwords | first | .value')"; echo "${acr_password}"

echo "${acr_password}" | docker login "${acr_name}".azurecr.io --username "${acr_name}" --password-stdin
docker tag "python-azuresql-mwe:Dockerfile" "${acr_name}.azurecr.io/python-azuresql-mwe:latest"
docker push "${acr_name}.azurecr.io/python-azuresql-mwe:latest"
az acr repository list -n "${acr_name}"
```


Configure App Service to deploy the image from the registry

```bash
web_app_name="django-azure-sql-webapp"
web_app_plan_name="${web_app_name}-plan"

az appservice plan create --name "${web_app_plan_name}" \
    --resource-group "${resource_group}" --is-linux

az webapp create --resource-group "${resource_group}" \
    --plan "${web_app_plan_name}" \
    --name "${web_app_name}" \
    --deployment-container-image-name "${acr_name}.azurecr.io/python-azuresql-mwe:latest"

az webapp config appsettings set --resource-group "${resource_group}" \
    --name "${web_app_name}" \
    --settings WEBSITES_PORT=8000 @app_settings.json

webapp_principal_id="$(az webapp identity assign --resource-group "${resource_group}" \
    --name "${web_app_name}" \
    --query principalId \
    --output tsv)"; echo "${webapp_principal_id}"

subscription_id="$(az account show --query id --output tsv)"; echo "${subscription_id}"

az role assignment create --assignee "${webapp_principal_id}" \
    --scope /subscriptions/${subscription_id}"/resourceGroups/"${resource_group}"/providers/Microsoft.ContainerRegistry/registries/${acr_name}" \
    --role "AcrPull"
```


Deploy the image and test the app

```bash
az webapp config container set --name "${web_app_name}" \
    --resource-group "${resource_group}" \
    --docker-custom-image-name "${acr_name}.azurecr.io/python-azuresql-mwe:latest" \
    --docker-registry-server-url https://"${acr_name}".azurecr.io
```

Go to https://django-azure-sql-webapp.azurewebsites.net/


Restart after making changes (optional):

```bash
az webapp restart --name "${web_app_name}" --resource-group "${resource_group}"
```


Access diagnostic logs

```bash
az webapp log config --name "${web_app_name}" \
--resource-group "${resource_group}" \
--docker-container-logging filesystem

az webapp log tail --name "${web_app_name}" --resource-group "${resource_group}"
```


Open SSH connection to container

Go to https://django-azure-sql-webapp.scm.azurewebsites.net/webssh/host

Or run this command:
    
```bash
az webapp ssh --resource-group "${resource_group}" --name "${web_app_name}"
```


Clean up resources

```bash
az group delete --no-wait
```
