#!/bin/sh
# Setup

IP_ADDR=$(ip addr show dev enp0s5|
    sed -ne 's/ *inet \(192.168.50.[0-9]*\).*/\1/p')

setup_prometheus(){
  wget  https://github.com/prometheus/prometheus/releases/download/v2.22.0/prometheus-2.22.0.linux-amd64.tar.gz
  tar xf prometheus-2.22.0.linux-amd64.tar.gz
  cat <<EOF > prometheus-2.22.0.linux-amd64/prometheus.yml
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'codelab-monitor'

rule_files:
- 'prometheus.rules.yml'

scrape_configs:
- job_name: 'prometheus'
  scrape_interval: 5s
  static_configs:
  - targets: ['${IP_ADDR}:9090']

- job_name: 'node'
  scrape_interval: 5s
  static_configs:
  - targets: ['${IP_ADDR}:8080', '${IP_ADDR}:8081']
    labels:
      group: 'production'

  - targets: ['${IP_ADDR}:8082']
    labels:
      group: 'canary'
EOF
  cat <<EOF > prometheus-2.22.0.linux-amd64/prometheus.rules.yml
groups:
- name: cpu-node
  rules:
  - record: job_instance_mode:node_cpu_seconds:avg_rate5m
    expr: avg by (job, instance, mode) (rate(node_cpu_seconds_total[5m]))
EOF
}

setup_node_exporter(){
  wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
  tar xf node_exporter-1.0.1.linux-amd64.tar.gz
}

start_node_exporter(){
  for i in 0 1 2;do
    ./node_exporter --web.listen-address ${IPADDR}:808${i} &
    echo $! > ~/.node_exporter_${i}-run
  done
}

start_prometheus(){
  ./prometheus --config.file=prometheus.yml
  echo $! > ~/.prometheus-run
}
