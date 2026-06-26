#!/bin/bash
set -e

echo "=== HeltClinica - Railway Entrypoint ==="

cd /home/frappe/frappe-bench

# Aguardar banco de dados
echo "Aguardando MySQL em $MYSQL_HOST:$MYSQL_PORT..."
for i in $(seq 1 30); do
  if mysqladmin ping -h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
    echo "MySQL pronto!"
    break
  fi
  echo "Tentativa $i/30..."
  sleep 3
done

# Aguardar Redis
echo "Aguardando Redis em $REDIS_HOST:$REDIS_PORT..."
for i in $(seq 1 20); do
  if redis-cli -h "$REDIS_HOST" -p "${REDIS_PORT:-6379}" ping 2>/dev/null | grep -q PONG; then
    echo "Redis pronto!"
    break
  fi
  echo "Tentativa $i/20..."
  sleep 3
done

# Configurar conexoes
echo "Configurando common_site_config.json..."
bench set-config -g db_host "$MYSQL_HOST"
bench set-config -gp db_port "${MYSQL_PORT:-3306}"
bench set-config -g redis_cache "redis://$REDIS_HOST:${REDIS_PORT:-6379}"
bench set-config -g redis_queue "redis://$REDIS_HOST:${REDIS_PORT:-6379}"
bench set-config -g redis_socketio "redis://$REDIS_HOST:${REDIS_PORT:-6379}"
bench set-config -gp socketio_port 9000
bench set-config -g developer_mode 0

DB_NAME="${SITE_DB_PREFIX:-heltclinica}_site1"

# Criar site se nao existir
if [ ! -f "sites/site1/site_config.json" ]; then
  echo "Criando banco de dados $DB_NAME..."
  mysql -h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  echo "Criando site site1..."
  bench new-site site1 \
    --mariadb-root-host "$MYSQL_HOST" \
    --mariadb-root-username "$MYSQL_USER" \
    --mariadb-root-password "$MYSQL_PASSWORD" \
    --admin-password "${ADMIN_PASSWORD:-admin}" \
    --db-name "$DB_NAME"

  echo "Instalando ERPNext..."
  bench --site site1 install-app erpnext

  echo "Instalando Healthcare..."
  bench --site site1 install-app healthcare
else
  echo "Site ja existe, executando migracoes..."
  bench --site site1 migrate
fi

# Configurar dominio publico
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  echo "Configurando hostname: $RAILWAY_PUBLIC_DOMAIN"
  bench --site site1 set-config hostname "$RAILWAY_PUBLIC_DOMAIN"
fi

echo "=== Iniciando servicos ==="

# Socket.IO
node /home/frappe/frappe-bench/apps/frappe/socketio.js &
echo "Socket.IO iniciado (PID $!)"

# Scheduler
bench schedule &
echo "Scheduler iniciado (PID $!)"

# Workers
bench worker --queue long,default,short &
echo "Worker long/default/short iniciado (PID $!)"
bench worker --queue short,default &
echo "Worker short/default iniciado (PID $!)"

# Gunicorn (foreground)
echo "Iniciando Gunicorn na porta ${PORT:-8000}..."
cd /home/frappe/frappe-bench/sites
exec gunicorn -b "0.0.0.0:${PORT:-8000}" \
  -w 2 \
  --threads 4 \
  --worker-class gthread \
  --worker-tmp-dir /dev/shm \
  --timeout 120 \
  frappe.app:application
