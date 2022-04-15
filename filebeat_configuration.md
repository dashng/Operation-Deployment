Filebeat Configuration
==========================

# The configuration sample of filebeat.yaml

```
filebeat.inputs:

- type: filestream

  enabled: true

  paths:
    - /var/log/*.log

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml

  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1

# ---------------------------- Kafka Output ----------------------------
output.kafka:
  hosts: ["10.124.44.48:9093"]
  topic: 'stc_log_test'
  partition.round_robin:
    reachable_only: false
  required_acks: 1
  compression: gzip
  max_message_bytes: 1000000
  ssl.certificate_authorities: ["/opt/cert/rootca.cert.pem"]
  ssl.certificate: "/opt/cert/mytestclient.cert.pem"
  ssl.key: "/opt/cert/mytestclient.key.pem"

# ================================= Processors =================================
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
```




