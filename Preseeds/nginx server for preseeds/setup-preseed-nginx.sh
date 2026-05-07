#!/usr/bin/env bash
set -euo pipefail

SITE_NAME="preseed"
PRESEED_ROOT="/srv/preseed"
NGINX_SITE="/etc/nginx/sites-available/${SITE_NAME}"
NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/${SITE_NAME}"
DEFAULT_SITE="/etc/nginx/sites-enabled/default"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

apt-get update
apt-get install -y nginx

mkdir -p "${PRESEED_ROOT}"

cat > "${NGINX_SITE}" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    location /preseed/ {
        alias ${PRESEED_ROOT}/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        try_files \$uri \$uri/ =404;
    }
}
EOF

rm -f "${DEFAULT_SITE}"
ln -sfn "${NGINX_SITE}" "${NGINX_SITE_ENABLED}"

nginx -t
systemctl enable --now nginx
systemctl reload nginx

chmod -R a+rX "${PRESEED_ROOT}"

SERVER_IP="$(hostname -I | awk '{print $1}')"

echo
echo "Preseed HTTP server is ready."
echo "Directory: ${PRESEED_ROOT}"
echo
echo "Put your preseed files into:"
echo "  ${PRESEED_ROOT}"
echo
echo "Example boot parameter:"
echo "  auto=true priority=critical url=http://${SERVER_IP}/preseed/preseed.cfg"

# chmod +x setup-preseed-nginx.sh && ./setup-preseed-nginx.sh