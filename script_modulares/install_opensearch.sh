#!/bin/bash

echo "[1/9] Parando serviços e removendo OpenSearch..."
sudo systemctl stop opensearch 2>/dev/null
sudo apt purge -y opensearch
sudo rm -rf /etc/opensearch /var/lib/opensearch /var/log/opensearch /var/run/opensearch
sudo rm -f /etc/apt/sources.list.d/opensearch.list /usr/share/keyrings/opensearch-keyring.gpg

echo "[2/9] Reinstalando dependências..."
sudo apt update
sudo apt install -y wget curl gnupg apt-transport-https openjdk-17-jdk

echo "[3/9] Adicionando chave GPG e repositório do OpenSearch..."
wget -qO - https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor | sudo tee /usr/share/keyrings/opensearch-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/opensearch.list > /dev/null
sudo apt update

echo "[4/9] Instalando OpenSearch..."
sudo mkdir -p /var/run/opensearch
sudo apt install -y opensearch || echo "⚠️ Aviso: falha no dpkg, tentando corrigir manualmente depois..."

echo "[5/9] Configurando OpenSearch com TLS..."
sudo tee /etc/opensearch/opensearch.yml > /dev/null <<EOF
cluster.name: opensearch-cluster
node.name: node-1
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
network.host: 0.0.0.0
http.port: 8200
discovery.type: single-node

plugins.security.ssl.transport.pemcert_filepath: /etc/certs/opensearch/opensearch.crt
plugins.security.ssl.transport.pemkey_filepath: /etc/certs/opensearch/opensearch.key
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/certs/ca/ca.crt

plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: /etc/certs/opensearch/opensearch.crt
plugins.security.ssl.http.pemkey_filepath: /etc/certs/opensearch/opensearch.key
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/certs/ca/ca.crt

plugins.security.allow_unsafe_democertificates: false
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=opensearch"

compatibility.override_main_response_version: true
EOF

echo "[6/9] Ajustando heap para 4GB..."
sudo sed -i 's/^-Xms.*/-Xms4g/' /etc/opensearch/jvm.options
sudo sed -i 's/^-Xmx.*/-Xmx4g/' /etc/opensearch/jvm.options

echo "[7/9] Garantindo permissões nos diretórios e certificados..."
sudo mkdir -p /var/lib/opensearch/nodes/0 /var/log/opensearch
sudo chown -R opensearch:opensearch /var/lib/opensearch /var/log/opensearch /var/run/opensearch
sudo chown -R opensearch:opensearch /etc/certs/opensearch /etc/certs/ca
sudo chmod -R 750 /var/lib/opensearch /var/log/opensearch /etc/certs/opensearch /etc/certs/ca

echo "[8/9] Habilitando e iniciando OpenSearch..."
sudo systemctl daemon-reexec
sudo systemctl enable opensearch
sudo systemctl restart opensearch

echo "[9/9] Verificando se está no ar com HTTPS..."
sleep 5
if curl -k https://localhost:8200 | grep -q cluster_name; then
    echo "✅ OpenSearch com TLS ativo e funcional na porta 8200!"
else
    echo "❌ Erro ao iniciar o OpenSearch. Verifique com: journalctl -xeu opensearch.service"
fi
