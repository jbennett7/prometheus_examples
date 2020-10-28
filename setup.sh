#!/bin/sh

WD=$(pwd)
REPO=https://github.com/prometheus/
P_VER=2.22.0
PROMETHEUS=prometheus-${P_VER}.linux-amd64
PROMETHEUS_URL=${REPO}/prometheus/releases/download/v${P_VER}/${PROMETHEUS}.tar.gz
NE_VER=1.0.1
NE=node_exporter-${NE_VER}.linux-amd64
NE_URL=${REPO}/node_exporter/releases/download/v${NE_VER}/${NE}.tar.gz
IP_ADDR=$(ip addr show dev enp0s5|
    sed -ne 's/ *inet \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')

setup_prometheus(){
  wget  ${PROMETHEUS_URL}
  tar xf ${PROMETHEUS}.tar.gz
  cat <<EOF > ${WD}/${PROMETHEUS}/prometheus.yml
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
  cat <<EOF > ${WD}/${PROMETHEUS}/prometheus.rules.yml
groups:
- name: cpu-node
  rules:
  - record: job_instance_mode:node_cpu_seconds:avg_rate5m
    expr: avg by (job, instance, mode) (rate(node_cpu_seconds_total[5m]))
EOF
}

setup_node_exporter(){
  wget ${NE_URL}
  tar xf ${NE}.tar.gz
}

start_node_exporter(){
  for i in 0 1 2;do
    ${WD}/${NE}/node_exporter --web.listen-address ${IPADDR}:808${i} &
    echo $! > ~/.node_exporter_${i}-run
  done
}

start_prometheus(){
  ${WD}/${PROMETHEUS}/prometheus \
      --config.file=${WD}/${PROMETHEUS}/prometheus.yml &
  echo $! > ~/.prometheus-run
}

shutdown_node_exporter(){
    for i in $(cat ~/.node_exporter*-run);do
        kill -SIGTERM ${i}
    done
}

shutdown_prometheus(){
    kill -SIGTERM ~/.prometheus-run
}
