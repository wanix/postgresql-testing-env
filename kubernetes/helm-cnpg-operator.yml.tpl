---
############################################################################
# https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg
############################################################################


resources:
  # If you want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  limits:
    cpu: 100m
    memory: 200Mi
  requests:
    cpu: 100m
    memory: 100Mi


monitoring:
  # -- Specifies whether the monitoring should be enabled. Requires Prometheus Operator CRDs.
  podMonitorEnabled: true
  grafanaDashboard:
    create: true
    # -- Allows overriding the namespace where the ConfigMap will be created, defaulting to the same one as the Release.
    namespace: "monitoring"
