#!/usr/bin/env bash
# Books A Nation: obtain + install Let's Encrypt SSL, enable https.
set -e
echo "== obtaining SSL certificate for booksanation.com =="
certbot --nginx -d booksanation.com -d www.booksanation.com --agree-tos --register-unsafely-without-email --redirect --non-interactive
echo "== restarting nginx =="
systemctl restart nginx
sleep 2
echo "== tests =="
curl -s -o /dev/null -w "http  booksanation.com  : %{http_code} (expect 301 to https)\n" -H "Host: booksanation.com" http://127.0.0.1/ || true
curl -s -o /dev/null -w "https booksanation.com  : %{http_code} (expect 200)\n" -k -H "Host: booksanation.com" https://127.0.0.1/ || true
echo "== SSL DONE =="
