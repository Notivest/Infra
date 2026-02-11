# Docker images -> Artifact Registry (GCP) [Generico]

Valores:
- project_id: YOUR_PROJECT_ID
- region: YOUR_REGION
- repo: YOUR_REPOSITORY
- tag: YOUR_TAG

Login al registry:
```bash
gcloud auth configure-docker YOUR_REGION-docker.pkg.dev
```

Crear el repo (solo si no existe):
```bash
gcloud artifacts repositories create YOUR_REPOSITORY --repository-format=docker --location YOUR_REGION
```

Tag + push por servicio (ajusta nombres de imagen local y remota):
```bash
docker tag frontend-notivest:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/frontend-notivest:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/frontend-notivest:YOUR_TAG

docker tag gateway-api:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/gateway-api:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/gateway-api:YOUR_TAG

docker tag price-fetcher:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/price-fetcher:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/price-fetcher:YOUR_TAG

docker tag portfolio-service:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/portfolio-service:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/portfolio-service:YOUR_TAG

docker tag alert-engine:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/alert-engine:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/alert-engine:YOUR_TAG

docker tag notification-service:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/notification-service:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/notification-service:YOUR_TAG

docker tag recommendation-service:YOUR_TAG YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/recommendation-service:YOUR_TAG
docker push YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPOSITORY/recommendation-service:YOUR_TAG
```
