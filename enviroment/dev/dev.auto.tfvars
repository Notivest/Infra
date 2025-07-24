location    = "eastus"
environment = "dev"

# todos los micro-servicios
services = {
  alert-engine = {
    image_tag = "latest"
    cpu       = 0.5
    memory    = "1Gi"
    env       = { DATABASE_URL = "secret:db-url" }
  }
  price-fetcher = {
    image_tag = "latest"
    cpu       = 0.5
    memory    = "1Gi"
    env       = {}
  }
  recommendation-service = {
    image_tag = "latest"
    cpu       = 0.5
    memory    = "1Gi"
    env       = {}
  }
  notification-service = {
    image_tag = "latest"
    cpu       = 0.5
    memory    = "1Gi"
    env       = {}
  }
  portfolio-service = {
    image_tag = "latest"
    cpu       = 1
    memory    = "2Gi"
    env       = {}
  }
  gateway-api = {
    image_tag = "latest"
    cpu       = 1
    memory    = "1Gi"
    env       = {}
  }
  rule-parser-service = {
    image_tag = "latest"
    cpu       = 0.5
    memory    = "1Gi"
    env       = {}
  }
  frontend-web = {
    image_tag = "latest"
    cpu       = 0.25
    memory    = "512Mi"
    env       = {}
  }
}
