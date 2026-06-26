#!/bin/bash
set -e

echo "=== HeltClinica - Railway Entrypoint ==="

cd /home/frappe/frappe-bench

# Linkar assets (comportamento do entrypoint original)
ASSETS_PATH="/home/frappe/frappe-bench/sites/assets"
BAKED_PATH="/home/frappe/frappe-bench/assets"
echo "Linkando assets..."
rm -rf "$ASSETS_PATH"
mkdir -p "$(dirname "$ASSETS_PATH")"
ln -sf "$BAKED_PATH" "$ASSETS_PATH"

# Resolver variaveis Railway
# Railway MySQL addon fornece: MYSQL_URL, MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE
# Railway Redis addon fornece: REDIS_URL
DB_HOST="${MYSQL_HOST:-${RAILWAY_MYSQL_HOST:-db}}"
DB_PORT="${MYSQL_PORT:-3306}"
DB_USER="${MYSQL_USER:-root}"
DB_PASS="${MYSQL_PASSWORD:-admin}"
DB_NAME="${MYSQL_DATABASE:-${SITE_DB_PREFIX:-heltclinica}_site1}"
SITE="${SITE_NAME:-site1}"
ADMIN_PWD="${ADMIN_PASSWORD:-admin}"
# Extrair host:port da REDIS_URL se estiver definida
if [ -n "$REDIS_URL" ]; then
  REDIS_HOST="${REDIS_HOST:-$(echo "$REDIS_URL" | sed -E 's|redis://([^:]+):.*|\1|')}"
  REDIS_PORT="${REDIS_PORT:-$(echo "$REDIS_URL" | sed -E 's|redis://[^:]+:([0-9]+).*|\1|')}"
fi
REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo "MySQL: $DB_HOST:$DB_PORT / $DB_NAME"
echo "Redis: $REDIS_HOST:$REDIS_PORT"
echo "Site: $SITE"

# Aguardar MySQL
echo "Aguardando MySQL..."
for i in $(seq 1 30); do
  if mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; then
    echo "MySQL pronto!"
    break
  fi
  echo "Tentativa $i/30..."
  sleep 3
done

# Aguardar Redis
echo "Aguardando Redis..."
for i in $(seq 1 20); do
  if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q PONG; then
    echo "Redis pronto!"
    break
  fi
  echo "Tentativa $i/20..."
  sleep 3
done

# Configurar conexoes globais
echo "Configurando common_site_config.json..."
bench set-config -g db_host "$DB_HOST"
bench set-config -gp db_port "$DB_PORT"
bench set-config -g redis_cache "redis://$REDIS_HOST:$REDIS_PORT"
bench set-config -g redis_queue "redis://$REDIS_HOST:$REDIS_PORT"
bench set-config -g redis_socketio "redis://$REDIS_HOST:$REDIS_PORT"
bench set-config -gp socketio_port 9000
bench set-config -g developer_mode 0

# Criar site se nao existir
if [ ! -f "sites/$SITE/site_config.json" ]; then
  echo "Criando site $SITE com banco $DB_NAME..."

  bench new-site "$SITE" \
    --mariadb-root-username "$DB_USER" \
    --mariadb-root-password "$DB_PASS" \
    --admin-password "$ADMIN_PWD" \
    --db-name "$DB_NAME"

  echo "Instalando ERPNext..."
  bench --site "$SITE" install-app erpnext

  echo "Instalando Healthcare..."
  bench --site "$SITE" install-app healthcare
else
  echo "Site $SITE ja existe, executando migracoes..."
  bench --site "$SITE" migrate
fi

# Configurar hostname para o dominio Railway
RAILWAY_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-${RAILWAY_STATIC_URL:-$SITE}}"
echo "Configurando hostname: $RAILWAY_DOMAIN"
bench --site "$SITE" set-config hostname "$RAILWAY_DOMAIN"

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
