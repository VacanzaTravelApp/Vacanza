Write-Host "VACANZA Offline PostgreSQL + pgAdmin Windows kurulumu basliyor..." -ForegroundColor Cyan

# 1) Klasorler
New-Item -ItemType Directory -Force -Path "vacanza-db\init" | Out-Null
New-Item -ItemType Directory -Force -Path "vacanza-db\pgadmin\data" | Out-Null

# 2) docker-compose.yml
$composeContent = @"
version: '3.9'

services:
  vacanza-postgis:
    image: postgis/postgis:15-3.4
    container_name: vacanza_postgis
    environment:
      POSTGRES_USER: vacanza_master
      POSTGRES_PASSWORD: vacanza_password
      POSTGRES_DB: postgres
    ports:
      - '5434:5432'
    volumes:
      - vacanza_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d
    restart: unless-stopped

  pgadmin:
    image: dpage/pgadmin4
    container_name: vacanza_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin123
    ports:
      - '5050:80'
    volumes:
      - ./pgadmin/data:/var/lib/pgadmin
    restart: unless-stopped

volumes:
  vacanza_data:
"@

Set-Content -Path "vacanza-db\docker-compose.yml" -Value $composeContent -Encoding UTF8

# 3) SQL Scriptler
Set-Content -Path "vacanza-db\init\01-create-databases.sql" -Value @"
CREATE DATABASE vacanza_prod;
"@ -Encoding UTF8

Set-Content -Path "vacanza-db\init\02-enable-postgis.sql" -Value @"
\connect vacanza_prod;
CREATE EXTENSION IF NOT EXISTS postgis;
"@ -Encoding UTF8

# 4) Docker Compose baslat
Write-Host "Docker container'lar baslatiliyor..." -ForegroundColor Yellow

Push-Location "vacanza-db"
docker compose up -d
Pop-Location

Start-Sleep -Seconds 5

# 5) Kontrol
$pg = docker ps --format "{{.Names}}" | Select-String "vacanza_postgis"
$admin = docker ps --format "{{.Names}}" | Select-String "vacanza_pgadmin"

if ($pg) {
    Write-Host "PostgreSQL (PostGIS) calisiyor -> Port: 5434" -ForegroundColor Green
} else {
    Write-Host "PostgreSQL CALISMADI!" -ForegroundColor Red
}

if ($admin) {
    Write-Host "pgAdmin calisiyor -> http://localhost:5050" -ForegroundColor Green
    Write-Host "Email: admin@admin.com"
    Write-Host "Password: admin123"
} else {
    Write-Host "pgAdmin CALISMADI!" -ForegroundColor Red
}

Write-Host "Kurulum tamamlandi! VACANZA Offline DB Windows ortaminda hazir." -ForegroundColor Cyan
