#!/bin/bash

set -e

PROJECT_NAME="$1"
shift

# Default values
PROJECT_INDEX=0
PG_MASTERS=1
MYSQL_MASTERS=1
WITH_SERVICES=(redis mongodb clickhouse n8n minio mailpit nginx)

# Parse arguments
for arg in "$@"
do
  case $arg in
    --index=*)
      PROJECT_INDEX="${arg#*=}"
      ;;
    --pg-master=*)
      PG_MASTERS="${arg#*=}"
      ;;
    --mysql-master=*)
      MYSQL_MASTERS="${arg#*=}"
      ;;
    --with=*)
      IFS=',' read -r -a WITH_SERVICES <<< "${arg#*=}"
      ;;
    *)
      echo "Unknown option: $arg" && exit 1
      ;;
  esac
done

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 <project-name> [--index=N] [--pg-master=N] [--mysql-master=N] [--with=svc1,svc2,...]"
  exit 1
fi

BASE_DOMAIN="ojie.dev"
PROJECT_DOMAIN="${PROJECT_NAME}.${BASE_DOMAIN}"
PROJECT_DIR="./${PROJECT_NAME}"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.${PROJECT_NAME}.yml"
ENV_FILE="${PROJECT_DIR}/.env"
PORT_DOC_FILE="${PROJECT_DIR}/PORT_MAP.txt"

mkdir -p "$PROJECT_DIR"
> "$ENV_FILE"
> "$PORT_DOC_FILE"

# Docker service port base 8PSI
function gen_port() {
  local S="$1"
  local I="$2"
  echo "8${PROJECT_INDEX}${S}${I}"
}

function write_port() {
  echo "$1=$2" >> "$ENV_FILE"
  echo "$1 => $2" >> "$PORT_DOC_FILE"
}

function create_service_dir() {
  mkdir -p "$PROJECT_DIR/database/$1/$2"
}

# Start writing YAML
cat > "$COMPOSE_FILE" <<EOF
version: '3.8'

services:
EOF

# PostgreSQL Masters
declare -i i=0
while [ $i -lt $PG_MASTERS ]; do
  port=$(gen_port 0 $i)
  var="PG_MASTER$((i+1))_PORT"
  write_port $var $port
  create_service_dir postgres master$((i+1))
  cat >> "$COMPOSE_FILE" <<EOF
  postgres_master$((i+1)):
    image: postgres:17
    container_name: postgres-master$((i+1))-${PROJECT_NAME}
    ports:
      - "\${$var}:5432"
    volumes:
      - ./database/postgres/master$((i+1)):/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
    networks:
      - development
EOF
  ((i++))
done

# MySQL Masters
i=0
while [ $i -lt $MYSQL_MASTERS ]; do
  port=$(gen_port 1 $i)
  var="MYSQL_MASTER$((i+1))_PORT"
  write_port $var $port
  create_service_dir mysql master$((i+1))
  cat >> "$COMPOSE_FILE" <<EOF
  mysql_master$((i+1)):
    image: mysql:9.0
    container_name: mysql-master$((i+1))-${PROJECT_NAME}
    ports:
      - "\${$var}:3306"
    volumes:
      - ./database/mysql/master$((i+1)):/var/lib/mysql
    environment:
      MYSQL_DATABASE: app
      MYSQL_USER: app
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: root
    networks:
      - development
EOF
  ((i++))
done

# Optional services (1 instance only)
declare -A SERVICE_ID=(
  [mongodb]=2
  [redis]=3
  [clickhouse]=4
  [n8n]=5
  [minio]=6
  [mailpit]=7
  [nginx]=8
)

for svc in "${WITH_SERVICES[@]}"; do
  sid="${SERVICE_ID[$svc]}"
  port=$(gen_port $sid 0)
  var="$(echo $svc | tr '[:lower:]' '[:upper:]')_PORT"
  write_port $var $port

  case $svc in
    redis)
      mkdir -p "$PROJECT_DIR/database/redis"
      cat >> "$COMPOSE_FILE" <<EOF
  redis:
    image: redis:7
    container_name: redis-${PROJECT_NAME}
    ports:
      - "\${$var}:6379"
    volumes:
      - ./database/redis:/data
    networks:
      - development
EOF
      ;;
    mongodb)
      mkdir -p "$PROJECT_DIR/database/mongodb"
      cat >> "$COMPOSE_FILE" <<EOF
  mongodb:
    image: mongo:latest
    container_name: mongodb-${PROJECT_NAME}
    ports:
      - "\${$var}:27017"
    volumes:
      - ./database/mongodb:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: secret
    networks:
      - development
EOF
      ;;
    clickhouse)
      mkdir -p "$PROJECT_DIR/database/clickhouse"
      cat >> "$COMPOSE_FILE" <<EOF
  clickhouse:
    image: clickhouse/clickhouse-server
    container_name: clickhouse-${PROJECT_NAME}
    ports:
      - "\${$var}:8123"
    volumes:
      - ./database/clickhouse:/var/lib/clickhouse
    networks:
      - development
EOF
      ;;
    n8n)
      mkdir -p "$PROJECT_DIR/n8n"
      cat >> "$COMPOSE_FILE" <<EOF
  n8n:
    image: n8nio/n8n
    container_name: n8n-${PROJECT_NAME}
    ports:
      - "\${$var}:5678"
    volumes:
      - ./n8n:/home/node/.n8n
    networks:
      - development
EOF
      ;;
    minio)
      mkdir -p "$PROJECT_DIR/bucket"
      cat >> "$COMPOSE_FILE" <<EOF
  minio:
    image: minio/minio
    container_name: minio-${PROJECT_NAME}
    ports:
      - "\${$var}:9000"
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: secret
    volumes:
      - ./bucket:/data
    networks:
      - development
EOF
      ;;
    mailpit)
      cat >> "$COMPOSE_FILE" <<EOF
  mailpit:
    image: axllent/mailpit
    container_name: mailpit-${PROJECT_NAME}
    ports:
      - "\${$var}:8025"
    networks:
      - development
EOF
      ;;
    nginx)
      mkdir -p "$PROJECT_DIR/nginx"
      cat >> "$COMPOSE_FILE" <<EOF
  nginx:
    image: nginx:latest
    container_name: nginx-${PROJECT_NAME}
    ports:
      - "\${$var}:80"
    volumes:
      - ./nginx:/etc/nginx/conf.d
    networks:
      - development
EOF
      ;;
  esac
done

# Define external network
cat >> "$COMPOSE_FILE" <<EOF

networks:
  development:
    external: true
EOF

echo "✅ Project $PROJECT_NAME generated with compose + port map."
echo "📂 Folder: $PROJECT_DIR"
echo "📄 Compose: $COMPOSE_FILE"
echo "🔧 Ports in: $ENV_FILE"
echo "📘 Map in: $PORT_DOC_FILE"
