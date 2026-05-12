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
    podMonitor:
      enabled: true # https://cloudnative-pg.io/docs/1.29/monitoring/#deprecation-of-automatic-podmonitor-creation
                     # still applying it, wait for tls usage in monitoring not yet available
                     # https://github.com/cloudnative-pg/charts/blob/main/charts/cluster/templates/cluster.yaml#L128-L140
    prometheusRule:
      excludeRules: # https://github.com/cloudnative-pg/charts/issues/825
        - CNPGClusterLogicalReplicationErrorsCritical
        - CNPGClusterLogicalReplicationErrors
        - CNPGClusterLogicalReplicationStoppedCritical
        - CNPGClusterLogicalReplicationStopped

poolers:
  - name: rw # real name is calculated with $fullnameOverride
    type: rw
    instances: ${PGPOOLERINSTANCESNUMBER}
    monitoring:
      enabled: true
      podMonitor:
        enabled: true
        relabelings:
          - targetLabel: type
            replacement: rw
  - name: ro # real name is calculated with $fullnameOverride
    type: ro
    instances: ${PGPOOLERINSTANCESNUMBER}
    monitoring:
      enabled: true
      podMonitor:
        enabled: true
        relabelings:
          - targetLabel: type
            replacement: ro
