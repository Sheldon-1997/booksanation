#!/usr/bin/env bash
# Books A Nation bootstrap v2: deploy + open firewall + ensure nginx.
set -e
cd /srv
echo "== downloading code =="
wget -q -O booksanation-deploy.zip https://raw.githubusercontent.com/sheldon-1997/booksanation/main/booksanation-deploy.zip
rm -rf booksanation
python3 -m zipfile -e booksanation-deploy.zip booksanation
echo "== running deploy script =="
bash booksanation/deploy/vps-setup.sh || true
echo "== ensuring nginx is running =="
systemctl enable nginx || true
systemctl restart nginx || true
echo "== opening firewall for web (80/443) =="
if command -v ufw >/dev/null 2>&1; then
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw status || true
fi
# In case iptables has a blocking INPUT policy, accept http/https explicitly.
if command -v iptables >/dev/null 2>&1; then
  iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 80 -j ACCEPT || true
  iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j ACCEPT || true
fi
echo "== what is listening on port 80 =="
ss -tlnp | grep ':80' || echo "NOTHING LISTENING ON 80"
echo "== local test =="
curl -s -o /dev/null -w "localhost HTTP: %{http_code}\n" -H "Host: booksanation.com" http://127.0.0.1/ || true
echo "== ALL DONE =="
