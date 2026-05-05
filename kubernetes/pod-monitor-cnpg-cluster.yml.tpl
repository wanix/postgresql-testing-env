---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: pg-cluster-${PGINSTANCENAME}
spec:
  selector:
    matchLabels:
      "cnpg.io/cluster": pg-cluster-${PGINSTANCENAME}
  podMetricsEndpoints:
    - port: metrics
      scheme: https
      tlsConfig:
        ca:
          secret:
            name: pg-cluster-${PGINSTANCENAME}-ca
            key: ca.crt
        serverName: pg-cluster-${PGINSTANCENAME}-rw
