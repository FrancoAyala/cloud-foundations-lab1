#!/bin/bash
# Lab 08 — user-data: bootstrap de postgres self-managed en EC2
# AVISO: En LocalStack esto se almacena pero NO se ejecuta.
# En AWS real correría al primer arranque de la instancia.
#
# Carga operativa que este script representa (y que RDS hace por vos):
#   1. Leer el secret de Secrets Manager
#   2. Instalar postgres-server
#   3. Configurar listen_addresses y pg_hba.conf
#   4. Arrancar el servicio (systemd)
#   5. Crear usuario y base
#   6. Configurar cron de backups a S3

set -e

# 1. Leer credenciales del secret (el rol IAM permite esto sin claves en disco)
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id app/db --query SecretString --output text)
DB_USER=$(echo $SECRET | python3 -c "import json,sys;print(json.load(sys.stdin)['username'])")
DB_PASS=$(echo $SECRET | python3 -c "import json,sys;print(json.load(sys.stdin)['password'])")
DB_NAME=$(echo $SECRET | python3 -c "import json,sys;print(json.load(sys.stdin)['dbname'])")

# 2. Instalar postgres
apt-get update -q
apt-get install -y postgresql-16

# 3. Configurar acceso de red
echo "listen_addresses = '*'" >> /etc/postgresql/16/main/postgresql.conf
echo "host all all 10.0.0.0/16 scram-sha-256" >> /etc/postgresql/16/main/pg_hba.conf

# 4. Arrancar servicio
systemctl enable postgresql
systemctl start postgresql

# 5. Crear usuario y base
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

# 6. Cron de backup a S3 (cada día a las 3am)
echo "0 3 * * * postgres pg_dump $DB_NAME | gzip | aws s3 cp - s3://course-data-lake/backups/db/\$(date +\%Y\%m\%d).sql.gz" \
  >> /etc/cron.d/postgres-backup
