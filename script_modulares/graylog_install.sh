#!/bin/bash

set -e

echo "[+] Atualizando sistema..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https openjdk-17-jre-headless curl gpg

echo "[+] Instalando MongoDB 6..."
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update && sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

echo "[+] Instalando Graylog 6..."
wget https://packages.graylog2.org/repo/packages/graylog-6.0-repository_latest.deb
sudo dpkg -i graylog-6.0-repository_latest.deb
sudo apt update && sudo apt install -y graylog-server

echo "[+] Gerando hashes de senha..."
SECRET=$(pwgen -N 1 -s 96)
PASSWORD="ED#DSs4d1eew3@#ed4sff15e1w"
HASH=$(echo -n "$PASSWORD" | sha256sum | awk '{print $1}')

echo "[+] Configurando Graylog..."
sudo sed -i "s|^password_secret =.*|password_secret = $SECRET|" /etc/graylog/server/server.conf
sudo sed -i "s|^root_password_sha2 =.*|root_password_sha2 = $HASH|" /etc/graylog/server/server.conf
sudo sed -i "s|^elasticsearch_hosts =.*|elasticsearch_hosts = http://127.0.0.1:9200|" /etc/graylog/server/server.conf
sudo sed -i "s|^#http_bind_address =.*|http_bind_address = 0.0.0.0:9000|" /etc/graylog/server/server.conf
sudo sed -i "s|^#elasticsearch_disable_version_check =.*|elasticsearch_disable_version_check = true|" /etc/graylog/server/server.conf

echo "[+] Iniciando Graylog..."
sudo systemctl daemon-reload
sudo systemctl enable --now graylog-server

echo "[✓] Graylog 6 instalado com sucesso! Acesse: http://<seu-ip>:9000"
