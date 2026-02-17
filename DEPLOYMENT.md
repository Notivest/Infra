# Deploy en GCP (Terraform + Docker)

Guia actualizada para desplegar la plataforma completa usando este repo (`Infra`) y Terraform.

## Requisitos
- Google Cloud SDK (`gcloud`)
- Terraform
- Docker
- Permisos en GCP para: Cloud Run, Artifact Registry, Secret Manager, Cloud SQL, Compute Load Balancer e IAM

## 1) Autenticacion y proyecto
```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## 2) Artifact Registry
Crear el repositorio Docker si no existe:
```powershell
gcloud artifacts repositories create notivest --repository-format=docker --location us-central1
```

## 3) Build, tag y push de imagenes
Desde cada repo de servicio (donde esta el `Dockerfile`):
```powershell
docker build -t frontend-notivest:latest .
docker build -t gateway-api:latest .
docker build -t price-fetcher:latest .
docker build -t portfolio-service:latest .
docker build -t alert-engine:latest .
docker build -t notification-service:latest .
docker build -t recommendation-service:latest .
```

Tag + push (ejemplo; repetir para cada servicio):
```powershell
docker tag frontend-notivest:latest us-central1-docker.pkg.dev/YOUR_PROJECT_ID/notivest/frontend-notivest:latest
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/notivest/frontend-notivest:latest
```

Nombres esperados por `terraform/terraform.tfvars.example`:
- `frontend-notivest`
- `gateway-api`
- `price-fetcher`
- `portfolio-service`
- `alert-engine`
- `notification-service`
- `recommendation-service`

## 4) Configurar Terraform
Crear `terraform/terraform.tfvars` (esta en `.gitignore`):
```powershell
Copy-Item terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Editar `terraform/terraform.tfvars` y completar al menos:
- `project_id`, `region`, `domain_root`
- `services.*.image` con los tags que pusheaste
- `AUTH0_*`, URLs internas y variables de cada servicio
- `cloudsql_users` con passwords fuertes
- `secret_env`: solo nombres de secret (no valores)

## 5) Secret Manager
El `tfvars.example` actual usa estos secretos:

```text
frontend-auth0-secret
frontend-auth0-client-id
frontend-auth0-client-secret
gateway-auth0-client-id
gateway-auth0-client-secret
finnhub-api-key
polygon-api-key
price-fetcher-new-relic-license-key
portfolio-db-password
portfolio-new-relic-license-key
alertengine-db-password
pricefetcher-client-id
pricefetcher-client-secret
notification-db-password
portfolio-auth0-client-secret
notification-smtp-password
recommendation-db-password
llm-api-key
market-events-api-key
svc-account-client-id
svc-account-client-secret
new-relic-api-key
recommendation-new-relic-license-key
```

Crear secretos (idempotente):
```powershell
$PROJECT_ID = "YOUR_PROJECT_ID"
$secrets = @(
  "frontend-auth0-secret",
  "frontend-auth0-client-id",
  "frontend-auth0-client-secret",
  "gateway-auth0-client-id",
  "gateway-auth0-client-secret",
  "finnhub-api-key",
  "polygon-api-key",
  "price-fetcher-new-relic-license-key",
  "portfolio-db-password",
  "portfolio-new-relic-license-key",
  "alertengine-db-password",
  "pricefetcher-client-id",
  "pricefetcher-client-secret",
  "notification-db-password",
  "portfolio-auth0-client-secret",
  "notification-smtp-password",
  "recommendation-db-password",
  "llm-api-key",
  "market-events-api-key",
  "svc-account-client-id",
  "svc-account-client-secret",
  "new-relic-api-key",
  "recommendation-new-relic-license-key"
)

foreach ($s in $secrets) {
  gcloud secrets describe $s --project $PROJECT_ID *> $null
  if ($LASTEXITCODE -ne 0) {
    gcloud secrets create $s --replication-policy=automatic --project $PROJECT_ID
  }
}
```

Agregar una version por secreto (valor distinto por cada uno):
```powershell
foreach ($s in $secrets) {
  $value = Read-Host "Valor para $s"
  $tmp = New-TemporaryFile
  Set-Content -Path $tmp -NoNewline -Value $value
  gcloud secrets versions add $s --data-file=$tmp --project $PROJECT_ID
  Remove-Item $tmp -Force
}
```

## 6) Importar secretos al state de Terraform (solo si los creaste manualmente)
Si los secretos ya existen fuera de Terraform, importalos antes de `apply`:

```powershell
Set-Location terraform
terraform init
$PROJECT_ID = "YOUR_PROJECT_ID"
# Usa el mismo array $secrets definido en el paso anterior.
```

```powershell
foreach ($s in $secrets) {
  terraform import "google_secret_manager_secret.secrets[`"$s`"]" "projects/$PROJECT_ID/secrets/$s"
}
```

## 7) Terraform plan/apply
```powershell
Set-Location terraform
terraform plan
terraform apply
```

## 7.1) Modo pausa (sin perder recursos)
En `terraform/terraform.tfvars`:
- `pause_mode = true` para pausar
- `pause_mode = false` para reanudar

Efectos de `pause_mode = true`:
- Cloud Run: `minScale = 0`
- Cloud Run: se remueve acceso publico (`allUsers`)
- Cloud SQL: queda encendida por defecto (`pause_cloud_sql = false`)

Opcional avanzado:
- `pause_cloud_sql = true` detiene Cloud SQL (`activation_policy = NEVER`)
- Si haces esto, Terraform puede fallar al leer `google_sql_user`/`google_sql_database` mientras la instancia esta detenida

## 8) DNS y verificacion
Despues del `apply`:
```powershell
terraform output load_balancer_ip
terraform output frontend_domains
terraform output api_domain
terraform output cloud_run_urls
```

Crear registros DNS para:
- `YOUR_DOMAIN`
- `www.YOUR_DOMAIN`
- `api.YOUR_DOMAIN`

Apuntar al `load_balancer_ip` y esperar a que el certificado SSL administrado quede activo.
