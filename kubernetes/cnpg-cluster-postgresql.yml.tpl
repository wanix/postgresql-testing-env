apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${PGINSTANCENAME}
spec:
  description: "Cluster ${PGINSTANCENAME} for testing PostgreSQL ${PGVERSION}"
  imageName: ${PGCONTAINERIMAGE}
  instances: ${PGINSTANCESNUMBER}
  primaryUpdateStrategy: unsupervised

#  postgresUID: ${PGUSERUID}  # Bug on init-container setting this
#  postgresGID: ${PGUSERGID}

  storage:
    pvcTemplate:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: ${PGDISKSIZE}
      storageClassName: manual

  monitoring:
    enablePodMonitor: ${PGPROMMONITORING}

  resources:
    requests:
      memory: "2Gi"
      cpu: "1"
    limits:
      memory: "3Gi"
      cpu: "2"
