#!/usr/bin/env bash
# Books A Nation fix: switch gunicorn to TCP 127.0.0.1:8001 (fixes 502 socket issue).
set -e
echo "== rewriting gunicorn service (TCP bind) =="
cat > /etc/systemd/system/booksanation.service <<'UNIT'
[Unit]
Description=Books A Nation (Gunicorn)
After=network.target postgresql.service

[Service]
WorkingDirectory=/srv/booksanation
ExecStart=/srv/booksanation/venv/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8001 --workers 3 --timeout 60
Restart=always
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
UNIT

echo "== rewriting nginx site (proxy to TCP) =="
cat > /etc/nginx/sites-available/booksanation <<'NGX'
server {
    listen 80;
    server_name booksanation.com www.booksanation.com 160.153.175.65;
    client_max_body_size 20M;
    location /static/ { alias /srv/booksanation/staticfiles/; expires 30d; }
    location /media/ { alias /srv/booksanation/media/; }
    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGX
ln -sf /etc/nginx/sites-available/booksanation /etc/nginx/sites-enabled/booksanation

echo "== restarting services =="
systemctl daemon-reload
systemctl restart booksanation
nginx -t
systemctl restart nginx
sleep 2
echo "== service state =="
systemctl is-active booksanation
echo "== local test =="
curl -s -o /dev/null -w "localhost HTTP: %{http_code}\n" -H "Host: booksanation.com" http://127.0.0.1/
curl -s -o /dev/null -w "gunicorn direct HTTP: %{http_code}\n" http://127.0.0.1:8001/ || true
echo "== FIX DONE =="
