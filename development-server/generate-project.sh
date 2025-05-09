#!/bin/bash

set -e

PROJECT_NAME="$1"
shift

# Default values
PROJECT_INDEX=0
WITH_SERVICES=(postgres mysql redis mongodb clickhouse n8n minio mailpit nginx php)

# Parse arguments
for arg in "$@"
do
  case $arg in
    --index=*)
      PROJECT_INDEX=$(( ${arg#*=} ))
      ;;
    *)
      echo "Unknown option: $arg" && exit 1
      ;;
  esac
done

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 <project-name> [--index=N]"
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
  printf "8%01d%01d%01d" "$PROJECT_INDEX" "$S" "$I"
}
function write_port() {
  echo "$1=$2" >> "$ENV_FILE"
  echo "$1 => $2" >> "$PORT_DOC_FILE"
}

function create_service_dir() {
  mkdir -p "$PROJECT_DIR/database/$1"
}

# Start writing YAML
cat > "$COMPOSE_FILE" <<EOF

services:
EOF

# Service ID Mapping
declare -A SERVICE_ID=(
  [postgres]=0
  [mysql]=1
  [mongodb]=2
  [redis]=3
  [clickhouse]=4
  [n8n]=5
  [minio]=6
  [mailpit]=7
  [nginx]=8
  [php]=9
)

# Service Generation
for svc in "${WITH_SERVICES[@]}"; do
  sid="${SERVICE_ID[$svc]}"
  port=$(gen_port $sid 0)
  var="$(echo $svc | tr '[:lower:]' '[:upper:]')_PORT"
  write_port $var $port

  case $svc in
    postgres)
      create_service_dir postgres
      cat >> "$COMPOSE_FILE" <<EOF
  postgres:
    image: postgres:17
    container_name: postgres-${PROJECT_NAME}
    ports:
      - "\${$var}:5432"
    volumes:
      - ./database/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
    networks:
      - development

EOF
      ;;
    mysql)
      create_service_dir mysql
      cat >> "$COMPOSE_FILE" <<EOF
  mysql:
    image: mysql:9.0
    container_name: mysql-${PROJECT_NAME}
    ports:
      - "\${$var}:3306"
    volumes:
      - ./database/mysql:/var/lib/mysql
    environment:
      MYSQL_DATABASE: app
      MYSQL_USER: app
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: root
    networks:
      - development

EOF
      ;;
    redis)
      create_service_dir redis
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
      create_service_dir mongodb
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
      create_service_dir clickhouse
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
      mkdir -p "$PROJECT_DIR/nginx/conf.d"
      mkdir -p "$PROJECT_DIR/nginx/hosting"
      mkdir -p "$PROJECT_DIR/code/laravel"
      cat > "$PROJECT_DIR/nginx/conf.d/default.conf" <<NGINX_DEFAULT
include /etc/nginx/conf.d/laravel/*.conf;
include /etc/nginx/conf.d/angular/*.conf;
NGINX_DEFAULT
      cat >> "$COMPOSE_FILE" <<EOF
  nginx:
    image: nginx:latest
    container_name: nginx-${PROJECT_NAME}
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./code/laravel:/home/www-data
      - ./nginx/hosting:/usr/share/nginx/html
    networks:
      - development
EOF
      ;;
    php)
      mkdir -p "$PROJECT_DIR/docker"
      cat > "$PROJECT_DIR/docker/default.Dockerfile" <<PHP_DOCKER
FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    zip unzip curl git libpq-dev libpng-dev libjpeg-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql gd mbstring xml

WORKDIR /var/www
PHP_DOCKER

      mkdir -p "$PROJECT_DIR/code"
      cat >> "$COMPOSE_FILE" <<EOF
  php:
    build:
      context: .
      dockerfile: ./docker/default.Dockerfile
    container_name: php-${PROJECT_NAME}
    volumes:
      - ./code:/var/www
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
