---
#####################################################################
# https://github.com/cloudnative-pg/charts/tree/main/charts/cluster
#####################################################################

# -- Override the name of the chart
nameOverride: "pg-cluster-${PGINSTANCENAME}"
# -- Override the full name of the chart
fullnameOverride: "pg-cluster-${PGINSTANCENAME}"

type: postgresql

version:
  # -- PostgreSQL major version to use
  postgresql: "${PGVERSION}"

mode: standalone

cluster:
  instances: ${PGINSTANCESNUMBER}
  imageName: "${PGCONTAINERIMAGE}"

  storage:
    size: ${PGDISKSIZE}
    storageClass: ${PGSTORAGECLASS}

  resources:
    limits:
      cpu: ${PGINSTANCECPU}
      memory: ${PGINSTANCEMEM}
    requests:
      cpu: ${PGINSTANCECPU}
      memory: ${PGINSTANCEMEM}

  monitoring:
    enabled: true
