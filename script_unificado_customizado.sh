#!/bin/bash
#
# Script Unificado de Instalação - Ambiente LAB 
# Componentes:
# - OpenSearch (puro) porta 8200 - sem segurança
# - MongoDB (via repositório oficial MongoDB 6.0)
# - Graylog (usando OpenSearch 8200)
# - Wazuh (All-in-One, usa OpenSearch interno porta 9200)
# - Grafana (porta 3000) - Customizado com a logo SOCBrazil 

set -e

echo "baixando imagens para customização"

cd /home/ 

git clone https://github.com/malvessocbrazil/Logos_SOCBrazil.git

echo "[1/7] Atualizando sistema e instalando dependências..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y apt-transport-https openjdk-17-jdk wget curl gpg gnupg2 software-properties-common pwgen apt-utils lsb-release

# ==============================================================================
# 2. INSTALAÇÃO DO OPENSEARCH (PURO - LAB) - SEM POST-INSTALL DEMO
# ==============================================================================
echo "[2/7] Instalando OpenSearch (puro - porta 8200, sem segurança)..."
wget -qO - https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor | sudo tee /usr/share/keyrings/opensearch-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch.list > /dev/null
sudo apt update

sudo apt download opensearch
sudo dpkg --unpack opensearch_*_amd64.deb

sudo mkdir -p /etc/opensearch
sudo tee /etc/opensearch/opensearch.yml > /dev/null <<EOF
cluster.name: opensearch-cluster
node.name: node-1
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
network.host: 0.0.0.0
transport.port: 8300
http.port: 8200
discovery.type: single-node
plugins.security.disabled: true
EOF

sudo dpkg --configure opensearch
sudo systemctl daemon-reload
sudo systemctl enable opensearch
sudo systemctl restart opensearch
sleep 10
curl -s http://localhost:8200 >/dev/null && echo "[OK] OpenSearch 8200 ativo!" || echo "[ERRO] OpenSearch não respondeu."

# ==============================================================================
# 3. INSTALAÇÃO DO MONGODB (CORRIGIDO - REPOSITÓRIO OFICIAL)
# ==============================================================================
echo "[3/7] Instalando MongoDB (repositório oficial 6.0)..."
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod
sudo systemctl status mongod --no-pager || true

# ==============================================================================
# 4. INSTALAÇÃO DO GRAYLOG
# ==============================================================================
echo "[4/7] Instalando Graylog..."
wget https://packages.graylog2.org/repo/packages/graylog-5.1-repository_latest.deb -O graylog-repo.deb
sudo dpkg -i graylog-repo.deb
sudo apt update
sudo apt install -y graylog-server

sudo tee /etc/graylog/server/server.conf > /dev/null <<EOF
password_secret = $(pwgen -N 1 -s 96)
root_password_sha2 = $(echo -n admin | sha256sum | awk '{print $1}')
root_email = "admin@example.com"
root_timezone = America/Sao_Paulo
is_master = true
node_id_file = /etc/graylog/server/node-id
elasticsearch_hosts = http://localhost:8200
http_bind_address = 0.0.0.0:8000
EOF

sudo systemctl enable graylog-server
sudo systemctl restart graylog-server

# ==============================================================================
# 5. INSTALAÇÃO DO WAZUH ALL-IN-ONE (COM CORREÇÃO AUTOMÁTICA DE CONFLITO)
# ==============================================================================
echo "[5/7] Preparando ambiente para instalar Wazuh All-in-One..."
echo "[*] Parando OpenSearch temporariamente para evitar conflito na porta 9300..."
sudo systemctl stop opensearch
sleep 5

echo "[*] Instalando Wazuh All-in-One (Indexador padrão 9200/9300)..."
curl -sO https://packages.wazuh.com/4.8/wazuh-install.sh
sudo bash wazuh-install.sh -a || {
  echo "[!] Falha na instalação do Wazuh. Verifique /var/log/wazuh-install.log"
  exit 1
}

echo "[*] Reiniciando OpenSearch após instalação do Wazuh..."
sudo systemctl start opensearch
sleep 10

# ==============================================================================
# 6. INSTALAÇÃO DO GRAFANA
# ==============================================================================
echo "======================================"
echo "    INSTALAÇÃO DO GRAFANA (CUSTOM)    "
echo "======================================"

# Solicita senha (oculta)
read -s -p "Digite a senha que deseja usar para o usuário admin: " GRAFANA_PASS
echo ""

# Confirma senha
read -s -p "Confirme a senha: " GRAFANA_PASS2
echo ""

# Validação
if [[ "$GRAFANA_PASS" != "$GRAFANA_PASS2" ]]; then
    echo "[ERRO] As senhas não coincidem. Execute o script novamente."
    exit 1
fi

echo "[INFO] Instalando dependências e adicionando repositório do Grafana..."
apt-get update
apt-get install -y software-properties-common gnupg2 curl

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list

apt-get update
apt-get install -y grafana

# Configura usuário e senha
cat <<EOF >> /etc/grafana/grafana.ini

[security]
admin_user = admin
admin_password = $GRAFANA_PASS
EOF

echo "[INFO] Habilitando e iniciando o Grafana..."
systemctl daemon-reexec
systemctl enable --now grafana-server

echo "Customizando com Logo Grafana"

echo "Customizando Ícone da aba do navegador"

cp /usr/share/grafana/public/img/fav32.png /usr/share/grafana/public/img/fav32.png.BKP

cd /home/Logos_SOCBrazil

mv socbrazil_sem_fundo.png fav32.png

cp fav32.png /usr/share/grafana/public/img/fav32.png

echo "Background da tela de login"

cp /usr/share/grafana/public/build/static/img/g8_login_dark.571d84ac.svg /usr/share/grafana/public/build/static/img/g8_login_dark.571d84ac.svg.BKP

cd /home/Logos_SOCBrazil

mv background.svg g8_login_dark.571d84ac.svg 

cp g8_login_dark.571d84ac.svg /usr/share/grafana/public/build/static/img/g8_login_dark.571d84ac.svg

echo "Customizando Logo principal"

cp /usr/share/grafana/public/build/static/img/grafana_icon.1e0deb6b.svg /usr/share/grafana/public/build/static/img/grafana_icon.1e0deb6b.svg.BKP

cd /home/Logos_SOCBrazil 

mv logo_text_dark-VZM4NTMC.svg grafana_icon.svg

cp grafana_icon.svg /usr/share/grafana/public/build/static/img/grafana_icon.1e0deb6b.svg


echo "Customizando Logo animado da tela de login"

cp /usr/share/grafana/public/build/img/grafana_icon.svg /usr/share/grafana/public/build/img/grafana_icon.svg.BKP

cd /home/Logos_SOCBrazil 

mv socbrazil_sem_fundo.svg grafana_icon.svg

cp grafana_icon.svg /usr/share/grafana/public/img/grafana_icon.svg

echo "Reiniciando o grafana"

sudo systemctl restart grafana-server



echo ""
echo "======================================"
echo "       INSTALAÇÃO FINALIZADA          "
echo "======================================"
echo " - OpenSearch (puro):     http://<IP>:8200"
echo " - Wazuh Dashboard:       https://<IP>"
echo " - Graylog:               http://<IP>:8000"
echo " - Grafana:               http://<IP>:3000"
