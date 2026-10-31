#!/usr/bin/env bash
# Books A Nation: update to latest code (preserves venv + .env, keeps TCP service).
set -e
cd /srv
echo "== downloading latest code =="
wget -q -O booksanation-deploy.zip https://raw.githubusercontent.com/sheldon-1997/booksanation/main/booksanation-deploy.zip
echo "== extracting over existing (venv and .env kept) =="
python3 -m zipfile -e booksanation-deploy.zip booksanation
cd booksanation
echo "== python deps =="
./venv/bin/pip install -q -r requirements.txt || true
echo "== migrate + collectstatic =="
./venv/bin/python manage.py migrate --noinput || true
./venv/bin/python manage.py collectstatic --noinput
chown -R www-data:www-data /srv/booksanation
echo "== restart services =="
systemctl restart booksanation
systemctl restart nginx
sleep 2
curl -s -o /dev/null -w "https booksanation.com: %{http_code} (expect 200)\n" -k -H "Host: booksanation.com" https://127.0.0.1/ || true
echo "== UPDATE DONE =="
