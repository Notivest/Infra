# Deploy en GCP (Terraform + Docker)

Guia pensada para alguien que clona este repo desde cero en Windows/PowerShell.

## Requisitos
- Google Cloud SDK (`gcloud`)
- Terraform
- Docker

## 1) Autenticacion y proyecto
```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## 2) Artifact Registry
Crear el repo (si no existe):
```powershell
gcloud artifacts repositories create notivest --repository-format=docker --location us-central1
```

## 3) Build de imagenes
Desde el repo de cada servicio (donde esta su Dockerfile):
```powershell
docker build -t frontend-notivest:latest .
docker build -t gateway-api:latest .
docker build -t price-fetcher:latest .
docker build -t portfolio-service:latest .
docker build -t alert-engine:latest .
docker build -t notification-service:latest .
docker build -t recommendation-service:latest .
```

## 4) Tag + push a Artifact Registry
Usa `docker-push.md` (en la raiz del repo). Ejemplo:
```powershell
docker tag frontend-notivest:latest us-central1-docker.pkg.dev/helical-cascade-477617-c9/notivest/frontend-notivest:latest
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/notivest/frontend-notivest:latest
```

## 5) Secret Manager
Crear secretos (si no existen):
```powershell
gcloud secrets create frontend-auth0-secret
gcloud secrets create frontend-auth0-client-id
gcloud secrets create frontend-auth0-client-secret
gcloud secrets create gateway-auth0-client-id
gcloud secrets create gateway-auth0-client-secret
gcloud secrets create finnhub-api-key
gcloud secrets create polygon-api-key
gcloud secrets create price-fetcher-new-relic-license-key
gcloud secrets create portfolio-db-password
gcloud secrets create portfolio-new-relic-license-key
gcloud secrets create alertengine-db-password
gcloud secrets create pricefetcher-client-id
gcloud secrets create pricefetcher-client-secret
gcloud secrets create notification-db-password
gcloud secrets create portfolio-auth0-client-secret
gcloud secrets create notification-smtp-password
gcloud secrets create recommendation-db-password
gcloud secrets create llm-api-key
gcloud secrets create svc-account-client-id
gcloud secrets create svc-account-client-secret
gcloud secrets create new-relic-api-key
gcloud secrets create recommendation-new-relic-license-key
```

Agregar versiones (reemplazar VALUE):
```powershell
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add frontend-auth0-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add frontend-auth0-client-id --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add frontend-auth0-client-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add gateway-auth0-client-id --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add gateway-auth0-client-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add finnhub-api-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add polygon-api-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add price-fetcher-new-relic-license-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add portfolio-db-password --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add portfolio-new-relic-license-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add alertengine-db-password --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add pricefetcher-client-id --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add pricefetcher-client-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add notification-db-password --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add portfolio-auth0-client-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add notification-smtp-password --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add recommendation-db-password --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add llm-api-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add svc-account-client-id --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add svc-account-client-secret --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add new-relic-api-key --data-file=-
cmd /c "echo|set /p=VALUE" | gcloud secrets versions add recommendation-new-relic-license-key --data-file=-
```

## 6) Configurar Terraform
Crear `terraform/terraform.tfvars` (esta en `.gitignore`):
```powershell
Copy-Item terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Editar `terraform/terraform.tfvars`:
- `project_id`, `region`, `domain_root`
- `services.*.image` con los tags que pusheaste
- `secret_env` debe contener **solo el nombre del secret** (no el valor)
- `cloudsql_users` debe tener passwords fuertes

## 7) Importar secrets al state de Terraform
Si creaste los secrets manualmente con `gcloud`, importalos:
```powershell
Set-Location terraform
terraform init
```

```powershell
terraform import 'google_secret_manager_secret.secrets[\"frontend-auth0-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/frontend-auth0-secret'
terraform import 'google_secret_manager_secret.secrets[\"frontend-auth0-client-id\"]' 'projects/YOUR_PROJECT_ID/secrets/frontend-auth0-client-id'
terraform import 'google_secret_manager_secret.secrets[\"frontend-auth0-client-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/frontend-auth0-client-secret'
terraform import 'google_secret_manager_secret.secrets[\"gateway-auth0-client-id\"]' 'projects/YOUR_PROJECT_ID/secrets/gateway-auth0-client-id'
terraform import 'google_secret_manager_secret.secrets[\"gateway-auth0-client-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/gateway-auth0-client-secret'
terraform import 'google_secret_manager_secret.secrets[\"finnhub-api-key\"]' 'projects/YOUR_PROJECT_ID/secrets/finnhub-api-key'
terraform import 'google_secret_manager_secret.secrets[\"polygon-api-key\"]' 'projects/YOUR_PROJECT_ID/secrets/polygon-api-key'
terraform import 'google_secret_manager_secret.secrets[\"price-fetcher-new-relic-license-key\"]' 'projects/YOUR_PROJECT_ID/secrets/price-fetcher-new-relic-license-key'
terraform import 'google_secret_manager_secret.secrets[\"portfolio-db-password\"]' 'projects/YOUR_PROJECT_ID/secrets/portfolio-db-password'
terraform import 'google_secret_manager_secret.secrets[\"portfolio-new-relic-license-key\"]' 'projects/YOUR_PROJECT_ID/secrets/portfolio-new-relic-license-key'
terraform import 'google_secret_manager_secret.secrets[\"alertengine-db-password\"]' 'projects/YOUR_PROJECT_ID/secrets/alertengine-db-password'
terraform import 'google_secret_manager_secret.secrets[\"pricefetcher-client-id\"]' 'projects/YOUR_PROJECT_ID/secrets/pricefetcher-client-id'
terraform import 'google_secret_manager_secret.secrets[\"pricefetcher-client-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/pricefetcher-client-secret'
terraform import 'google_secret_manager_secret.secrets[\"notification-db-password\"]' 'projects/YOUR_PROJECT_ID/secrets/notification-db-password'
terraform import 'google_secret_manager_secret.secrets[\"portfolio-auth0-client-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/portfolio-auth0-client-secret'
terraform import 'google_secret_manager_secret.secrets[\"notification-smtp-password\"]' 'projects/YOUR_PROJECT_ID/secrets/notification-smtp-password'
terraform import 'google_secret_manager_secret.secrets[\"recommendation-db-password\"]' 'projects/YOUR_PROJECT_ID/secrets/recommendation-db-password'
terraform import 'google_secret_manager_secret.secrets[\"llm-api-key\"]' 'projects/YOUR_PROJECT_ID/secrets/llm-api-key'
terraform import 'google_secret_manager_secret.secrets[\"svc-account-client-id\"]' 'projects/YOUR_PROJECT_ID/secrets/svc-account-client-id'
terraform import 'google_secret_manager_secret.secrets[\"svc-account-client-secret\"]' 'projects/YOUR_PROJECT_ID/secrets/svc-account-client-secret'
terraform import 'google_secret_manager_secret.secrets[\"new-relic-api-key\"]' 'projects/YOUR_PROJECT_ID/secrets/new-relic-api-key'
terraform import 'google_secret_manager_secret.secrets[\"recommendation-new-relic-license-key\"]' 'projects/YOUR_PROJECT_ID/secrets/recommendation-new-relic-license-key'
```

## 8) Terraform plan/apply
```powershell
terraform plan
terraform apply
```

## 9) DNS
Despues del apply:
```powershell
terraform output load_balancer_ip
terraform output cloud_run_urls
```

Crear registros DNS para:
- `notivest.com`
- `www.notivest.com`
- `api.notivest.com`

Apuntar al `load_balancer_ip` y esperar a que el certificado SSL quede activo.
