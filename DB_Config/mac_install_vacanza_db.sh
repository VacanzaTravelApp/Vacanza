#!/bin/bash

echo "🚀 VACANZA Offline PostgreSQL + pgAdmin kurulumu başlıyor..."

############################################
# 1) Klasörleri oluştur
############################################
mkdir -p vacanza-db/init
mkdir -p vacanza-db/pgadmin/data

############################################
# 2) PostgreSQL + PostGIS docker-compose oluştur
############################################
cat << 'EOF' > vacanza-db/docker-compose.yml
version: "3.9"

services:
  vacanza-postgis:
    image: postgis/postgis:15-3.4
    container_name: vacanza_postgis
    environment:
      POSTGRES_USER: vacanza_master
      POSTGRES_PASSWORD: vacanza_password
      POSTGRES_DB: postgres
    ports:
      - "5434:5432"
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
      - "5050:80"
    volumes:
      - ./pgadmin/data:/var/lib/pgadmin
    restart: unless-stopped

volumes:
  vacanza_data:
EOF

############################################
# 3) DB oluşturma scripti yaz
############################################
cat << 'EOF' > vacanza-db/init/01-create-databases.sql
CREATE DATABASE vacanza_prod;
EOF

############################################
# 4) PostGIS enable scripti yaz
############################################
cat << 'EOF' > vacanza-db/init/02-enable-postgis.sql
\connect vacanza_prod;
CREATE EXTENSION IF NOT EXISTS postgis;
EOF

############################################
# 5) Docker compose çalıştır
############################################
cd vacanza-db
echo "🐳 Docker container’ları başlatılıyor..."
docker-compose up -d

sleep 6

############################################
# 6) Başarı kontrolü
############################################
if docker ps --format "{{.Names}}" | grep -q "vacanza_postgis"; then
    echo "✅ PostgreSQL (PostGIS) başarıyla çalışıyor! Port: 5434"
else
    echo "❌ PostgreSQL çalışmadı!"
fi

if docker ps --format "{{.Names}}" | grep -q "vacanza_pgadmin"; then
    echo "✅ pgAdmin başarıyla çalışıyor! Port: http://localhost:5050"
    echo "🔑 Email: admin@admin.com"
    echo "🔑 Password: admin123"
else
    echo "❌ pgAdmin çalışmadı!"
fi

echo "🎉 Kurulum tamamlandı! Offline Vacanza DB’n hazır!"

