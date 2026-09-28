#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/pisanadam/miguel-konseri.git}"
APP_DIR="${APP_DIR:-/srv/phonk-concert/phonk_concert_server}"
TRACK_DIR="${TRACK_DIR:-/srv/phonk-concert/tracks}"
TMP_DIR="${TMP_DIR:-/srv/phonk-concert/tmp}"
ENV_FILE="${ENV_FILE:-/etc/phonk-concert.env}"
SERVICE_FILE="/etc/systemd/system/phonk-concert.service"
DOMAIN_DEFAULT="jennykonser.pisankus.dedyn.io"
PORT="${PORT:-3000}"
LIMIT_BYTES="${STORAGE_LIMIT_BYTES:-5368709120}"
MAX_UPLOAD_BYTES="${MAX_UPLOAD_BYTES:-262144000}"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Bu kurulum root yetkisi ister. 'sudo bash' ile calistir." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git patch curl ca-certificates nodejs ffmpeg nginx certbot

DOMAIN="${DOMAIN:-}"
if [[ -z "$DOMAIN" ]]; then
  if [[ -r "$ENV_FILE" ]] && grep -q '^DOMAIN=' "$ENV_FILE"; then
    DOMAIN="$(grep '^DOMAIN=' "$ENV_FILE" | tail -1 | cut -d= -f2-)"
  else
    printf 'Alan adi [%s]: ' "$DOMAIN_DEFAULT" > /dev/tty
    IFS= read -r DOMAIN < /dev/tty || true
    DOMAIN="${DOMAIN:-$DOMAIN_DEFAULT}"
  fi
fi

ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
if [[ -z "$ADMIN_PASSWORD" && -r "$ENV_FILE" ]]; then
  ADMIN_PASSWORD="$(grep '^ADMIN_PASSWORD=' "$ENV_FILE" | tail -1 | cut -d= -f2- || true)"
fi
if [[ -z "$ADMIN_PASSWORD" ]]; then
  printf 'Admin sifresi (/admin31): ' > /dev/tty
  IFS= read -rs ADMIN_PASSWORD < /dev/tty || true
  printf '\n' > /dev/tty
fi
if [[ -z "$ADMIN_PASSWORD" ]]; then
  echo "Admin sifresi bos olamaz." >&2
  exit 1
fi
if [[ "$ADMIN_PASSWORD" == *$'\n'* || "$ADMIN_PASSWORD" == *$'\r'* ]]; then
  echo "Admin sifresinde satir sonu kullanilamaz." >&2
  exit 1
fi

mkdir -p "$APP_DIR" "$TRACK_DIR" "$TMP_DIR"
chmod 755 /srv/phonk-concert "$APP_DIR" "$TRACK_DIR" "$TMP_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git clone --depth 1 "$REPO_URL" "$WORK/repo"
cd "$WORK/repo"

if [[ ! -f server.mjs ]]; then
  echo "Repo sunucu dosyasi eksik: server.mjs" >&2
  exit 1
fi

PATCH_FILE="server-mode.patch"
if [[ ! -f "$PATCH_FILE" && -f server-mode.patch.gz.b64 ]]; then
  base64 -d server-mode.patch.gz.b64 | gzip -dc > "$WORK/server-mode.patch"
  PATCH_FILE="$WORK/server-mode.patch"
fi
if [[ ! -f "$PATCH_FILE" ]]; then
  echo "Repo frontend patch'i eksik: server-mode.patch(.gz.b64)" >&2
  exit 1
fi

patch -p1 --forward --batch < "$PATCH_FILE"
node --check server.mjs

install -m 0644 index.html "$APP_DIR/index.html"
install -m 0644 server.mjs "$APP_DIR/server.mjs"

umask 077
cat > "$ENV_FILE" <<ENVEOF
HOST=0.0.0.0
PORT=$PORT
TRACK_DIR=$TRACK_DIR
TMP_DIR=$TMP_DIR
STORAGE_LIMIT_BYTES=$LIMIT_BYTES
MAX_UPLOAD_BYTES=$MAX_UPLOAD_BYTES
ADMIN_PASSWORD=$ADMIN_PASSWORD
DOMAIN=$DOMAIN
ENVEOF
chmod 600 "$ENV_FILE"

cat > "$SERVICE_FILE" <<SERVICEEOF
[Unit]
Description=Jenny Phonk Concert Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=/usr/bin/node $APP_DIR/server.mjs
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable phonk-concert >/dev/null
systemctl restart phonk-concert
sleep 1
curl -fsS "http://127.0.0.1:$PORT/api/health" >/dev/null

CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
if [[ ! -s "$CERT_DIR/fullchain.pem" || ! -s "$CERT_DIR/privkey.pem" ]]; then
  echo "TLS sertifikasi aliniyor: $DOMAIN"
  systemctl stop nginx 2>/dev/null || true
  if ! certbot certonly --standalone -d "$DOMAIN" --agree-tos --register-unsafely-without-email --non-interactive; then
    echo >&2
    echo "Sertifika alinamadi. DNS A kaydinin bu sunucunun public IP'sine gittigini kontrol et." >&2
    echo "Node servisi calisiyor: http://127.0.0.1:$PORT" >&2
    exit 1
  fi
fi

cat > /etc/nginx/sites-available/jennykonser <<NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_DIR/fullchain.pem;
    ssl_certificate_key $CERT_DIR/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 250m;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_request_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/phonk-concert
ln -sfn /etc/nginx/sites-available/jennykonser /etc/nginx/sites-enabled/jennykonser

mkdir -p /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh <<'HOOKEOF'
#!/bin/sh
systemctl reload nginx
HOOKEOF
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

nginx -t
systemctl enable nginx >/dev/null
systemctl restart nginx
systemctl enable --now certbot.timer >/dev/null 2>&1 || true

echo
echo "Kurulum tamam."
echo "Site : https://$DOMAIN"
echo "Admin: https://$DOMAIN/admin31"
echo "Ortak depo: $TRACK_DIR (5 GiB)"
echo "Servis: systemctl status phonk-concert --no-pager"
