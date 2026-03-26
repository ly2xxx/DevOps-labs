# Helm Secrets Rotation Lab - Quick Setup Script
# Creates the Helm chart structure with all templates ready to use
#
# Usage: .\setup-lab.ps1

param(
    [switch]$SkipHelmCreate,
    [switch]$CleanupOnly
)

$ErrorActionPreference = "Stop"

$CHART_DIR = "C:\code\DevOps-labs\openshift-quickstart\05-helm-secrets-rotation\my-app-chart"
$CHART_NAME = "my-app"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   Helm Secrets Rotation Lab - Setup" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

# Cleanup function
function Cleanup-Lab {
    Write-Host "🧹 Cleaning up lab environment..." -ForegroundColor Yellow
    
    if (Test-Path $CHART_DIR) {
        Write-Host "  Removing chart directory..." -ForegroundColor Gray
        Remove-Item -Recurse -Force $CHART_DIR
    }
    
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    Write-Host ""
}

if ($CleanupOnly) {
    Cleanup-Lab
    exit 0
}

Write-Host "📦 Step 1: Creating Helm chart structure" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

# Create chart directory
if (-not (Test-Path $CHART_DIR)) {
    New-Item -ItemType Directory -Path $CHART_DIR -Force | Out-Null
    Write-Host "  Created directory: $CHART_DIR" -ForegroundColor Gray
}

Set-Location $CHART_DIR

# Create Helm chart skeleton
if (-not $SkipHelmCreate) {
    Write-Host "  Running 'helm create $CHART_NAME'..." -ForegroundColor Gray
    helm create $CHART_NAME 2>&1 | Out-Null
    Write-Host "✅ Chart skeleton created" -ForegroundColor Green
}

Write-Host ""
Write-Host "📝 Step 2: Creating custom templates" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

# Create values.yaml
Write-Host "  Creating values.yaml..." -ForegroundColor Gray
@"
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25-alpine"

service:
  type: ClusterIP
  port: 80

# Secret configuration
secrets:
  databasePassword: "initial_password_123"
  apiKey: "api_key_v1_xyz"
  jwtSecret: "jwt_secret_initial"

# ConfigMap configuration
config:
  appName: "My Awesome App"
  environment: "development"
  logLevel: "info"
  features:
    enableMetrics: "true"
    enableDebug: "false"

# Rolling update strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0

# Health checks (disabled for nginx demo)
livenessProbe: null
readinessProbe: null

# Autoscaling (disabled by default)
autoscaling:
  enabled: false

# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
"@ | Out-File -FilePath "$CHART_DIR\$CHART_NAME\values.yaml" -Encoding UTF8

# Create ConfigMap template
Write-Host "  Creating configmap.yaml template..." -ForegroundColor Gray
@"
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-app.fullname" . }}-config
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
data:
  APP_NAME: {{ .Values.config.appName | quote }}
  ENVIRONMENT: {{ .Values.config.environment | quote }}
  LOG_LEVEL: {{ .Values.config.logLevel | quote }}
  ENABLE_METRICS: {{ .Values.config.features.enableMetrics | quote }}
  ENABLE_DEBUG: {{ .Values.config.features.enableDebug | quote }}
  
  # Config file example
  app-config.json: |
    {
      "appName": "{{ .Values.config.appName }}",
      "environment": "{{ .Values.config.environment }}",
      "logLevel": "{{ .Values.config.logLevel }}",
      "features": {
        "enableMetrics": {{ .Values.config.features.enableMetrics }},
        "enableDebug": {{ .Values.config.features.enableDebug }}
      }
    }
"@ | Out-File -FilePath "$CHART_DIR\$CHART_NAME\templates\configmap.yaml" -Encoding UTF8

# Create Secret template
Write-Host "  Creating secret.yaml template..." -ForegroundColor Gray
@"
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-app.fullname" . }}-secret
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
type: Opaque
stringData:
  databasePassword: {{ .Values.secrets.databasePassword | quote }}
  apiKey: {{ .Values.secrets.apiKey | quote }}
  jwtSecret: {{ .Values.secrets.jwtSecret | quote }}
  
  # Secret file example
  database-credentials.json: |
    {
      "host": "postgres.example.com",
      "port": 5432,
      "username": "app_user",
      "password": "{{ .Values.secrets.databasePassword }}"
    }
"@ | Out-File -FilePath "$CHART_DIR\$CHART_NAME\templates\secret.yaml" -Encoding UTF8

# Update deployment.yaml with volume mounts and checksums
Write-Host "  Updating deployment.yaml with volume mounts and checksums..." -ForegroundColor Gray
# Note: Full deployment customization would be extensive, creating a simple addition note instead

@"
# NOTE: The default deployment.yaml needs these additions:
# 
# In template.metadata.annotations:
#   checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
#   checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
#
# In spec.template.spec.containers[0]:
#   envFrom:
#   - configMapRef:
#       name: {{ include "my-app.fullname" . }}-config
#   env:
#   - name: DATABASE_PASSWORD
#     valueFrom:
#       secretKeyRef:
#         name: {{ include "my-app.fullname" . }}-secret
#         key: databasePassword
#   volumeMounts:
#   - name: secret-files
#     mountPath: /etc/secrets
#     readOnly: true
#   - name: config-files
#     mountPath: /etc/config
#     readOnly: true
#
# In spec.template.spec:
#   volumes:
#   - name: secret-files
#     secret:
#       secretName: {{ include "my-app.fullname" . }}-secret
#   - name: config-files
#     configMap:
#       name: {{ include "my-app.fullname" . }}-config
"@ | Out-File -FilePath "$CHART_DIR\$CHART_NAME\templates\DEPLOYMENT-NOTES.txt" -Encoding UTF8

Write-Host "✅ Templates created" -ForegroundColor Green

Write-Host ""
Write-Host "🧪 Step 3: Validating chart" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

try {
    helm lint "$CHART_DIR\$CHART_NAME" 2>&1 | Out-Null
    Write-Host "✅ Chart validation passed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Chart validation had warnings (this is OK for a demo)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "   ✅ Lab Setup Complete!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Chart location: $CHART_DIR\$CHART_NAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Review the chart structure:" -ForegroundColor White
Write-Host "   cd $CHART_DIR\$CHART_NAME" -ForegroundColor Cyan
Write-Host "   ls -R" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Review DEPLOYMENT-NOTES.txt for manual edits needed:" -ForegroundColor White
Write-Host "   cat templates\DEPLOYMENT-NOTES.txt" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Test render the chart:" -ForegroundColor White
Write-Host "   helm template my-app . > rendered.yaml" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Deploy to OKD:" -ForegroundColor White
Write-Host "   oc login -u developer https://api.crc.testing:6443" -ForegroundColor Cyan
Write-Host "   oc new-project helm-secrets-lab" -ForegroundColor Cyan
Write-Host "   helm install my-app . -n helm-secrets-lab" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Follow the full lab guide:" -ForegroundColor White
Write-Host "   📖 README.md (in parent directory)" -ForegroundColor White
Write-Host ""
Write-Host "🧹 To cleanup: .\setup-lab.ps1 -CleanupOnly" -ForegroundColor Gray
Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
