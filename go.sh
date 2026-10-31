#!/usr/bin/env bash
# Books A Nation one-shot bootstrap: download code, extract, deploy.
set -e
cd /srv
echo "== downloading code =="
wget -q -O booksanation-deploy.zip https://raw.githubusercontent.com/sheldon-1997/booksanation/main/booksanation-deploy.zip
echo "== extracting =="
rm -rf booksanation
python3 -m zipfile -e booksanation-deploy.zip booksanation
echo "== running deploy script =="
bash booksanation/deploy/vps-setup.sh
