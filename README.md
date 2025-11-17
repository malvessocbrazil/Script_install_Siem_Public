<img width="1128" height="191" alt="image" src="https://github.com/user-attachments/assets/28b4e2b2-de95-462f-b515-af4ec2013732" />



🛠️ Importante – Ajustes Após a Instalação

Após realizar a instalação utilizando o script unificado,
é necessário ajustar manualmente os arquivos de configuração conforme mostrado abaixo.

Esses ajustes garantem que o Graylog e o OpenSearch funcionem corretamente no ambiente.

📂 1. Configuração do Graylog

📄 Arquivo: /etc/graylog/server/server.conf

is_leader = true

node_id_file = /etc/graylog/server/node-id

password_secret = "YOUR_PASSWORD_SECRET"

root_password_sha2 = "YOUR_ROOT_PASSWORD_SHA2"

bin_dir = /usr/share/graylog-server/bin

data_dir = /var/lib/graylog-server

plugin_dir = /usr/share/graylog-server/plugin

http_bind_address = 0.0.0.0:8000

http_publish_uri = http://YOUR_GRAYLOG_ADDRESS:8000/

http_enable_cors = true

http_enable_gzip = true

stream_aware_field_types=false

disabled_retention_strategies = none,close

elasticsearch_disable_version_check = true

allow_leading_wildcard_searches = false

allow_highlighting = false

field_value_suggestion_mode = on

output_batch_size = 500

output_flush_interval = 1

output_fault_count_threshold = 5

output_fault_penalty_seconds = 30

processor_wait_strategy = blocking

ring_size = 65536

inputbuffer_ring_size = 65536

inputbuffer_wait_strategy = blocking

message_journal_enabled = true

message_journal_dir = /var/lib/graylog-server/journal

lb_recognition_period_seconds = 3

mongodb_uri = mongodb://localhost/graylog

mongodb_max_connections = 1000

job_scheduler_concurrency_limits = event-processor-execution-v1:2,notification-execution-v1:2

# - OpenSearch / Elasticsearch connection --
elasticsearch_hosts = http://127.0.0.1:8200

elasticsearch_connect_timeout = 10s

elasticsearch_socket_timeout = 60s

elasticsearch_max_total_connections = 200

elasticsearch_max_total_connections_per_route = 20

elasticsearch_discovery_enabled = false


📂 2. Configuração do OpenSearch

📄 Arquivo: /etc/opensearch/opensearch.yml

cluster.name: opensearch-cluster

node.name: node-1

path.data: /var/lib/opensearch

path.logs: /var/log/opensearch

network.host: 0.0.0.0

http.port: 8200

transport.port: 8300

discovery.type: single-node

plugins.security.disabled: true

logo apos execute o comando abaixo: 

systemctl restart graylog-server

systemctl restart opensearch

