#!/usr/bin/env bash
# Books A Nation: install a self-updating deploy agent (systemd timer).
# After this runs once, the server auto-pulls new code within ~3 min whenever
# the repo's VERSION file changes. No console/toggle needed again.
set -e
RAW="https://raw.githubusercontent.com/sheldon-1997/booksanation/main"

echo "== writing updater =="
cat > /usr/local/bin/ban-update.sh <<SH
#!/usr/bin/env bash
set -e
RAW="$RAW"
cd /srv
NEW=\$(wget -q -O- "\$RAW/VERSION" 2>/dev/null || echo "")
OLD=\$(cat /srv/.ban-version 2>/dev/null || echo "none")
[ -z "\$NEW" ] && exit 0
[ "\$NEW" = "\$OLD" ] && exit 0
echo "\$(date) updating \$OLD -> \$NEW"
wget -q -O booksanation-deploy.zip "\$RAW/booksanation-deploy.zip"
python3 -m zipfile -e booksanation-deploy.zip booksanation
cd booksanation
./venv/bin/pip install -q -r requirements.txt || true
./venv/bin/python manage.py migrate --noinput || true
./venv/bin/python manage.py collectstatic --noinput
chown -R www-data:www-data /srv/booksanation
systemctl restart booksanation
systemctl restart nginx
echo "\$NEW" > /srv/.ban-version
echo "\$(date) updated to \$NEW"
SH
chmod +x /usr/local/bin/ban-update.sh

echo "== systemd service + timer =="
cat > /etc/systemd/system/ban-update.service <<'UNIT'
[Unit]
Description=Books A Nation auto-update
After=network-online.target
[Service]
Type=oneshot
ExecStart=/usr/local/bin/ban-update.sh
UNIT

cat > /etc/systemd/system/ban-update.timer <<'UNIT'
[Unit]
Description=Books A Nation auto-update every 3 minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=3min
[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now ban-update.timer

echo "== first run now =="
/usr/local/bin/ban-update.sh || true
sleep 2
curl -s -o /dev/null -w "https booksanation.com: %{http_code}\n" -k -H "Host: booksanation.com" https://127.0.0.1/ 2>/dev/null || true
echo "== AUTO-UPDATE INSTALLED =="
