---
# original: https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/docs/src/samples/monitoring/kube-stack-config.yaml
enabled: true
kubeControllerManager:
  enabled: false
nodeExporter:
  enabled: false
defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false
    configReloaders: false
    general: false
    k8s: true
    kubeApiserver: false
    kubeApiserverAvailability: false
    kubeApiserverSlos: false
    kubelet: true
    kubeProxy: false
    kubePrometheusGeneral: true
    kubePrometheusNodeRecording: false
    kubernetesApps: false
    kubernetesResources: false
    kubernetesStorage: true
    kubernetesSystem: false
    kubeScheduler: false
    kubeStateMetrics: false
    network: false
    node: true
    nodeExporterAlerting: false
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true

#nodeSelector:
  #workload: monitor
prometheus:
  prometheusSpec:
    retention: 7d
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false
  #nodeSelector:
    #workload: monitor
grafana:
  enabled: true
  defaultDashboardsEnabled: false
  sidecar: # https://github.com/prometheus-community/helm-charts/issues/6419
    dashboards:
      enabled: true
    datasources:
      watchMethod: "SLEEP"
  persistence:
    enabled: false
    type: sts
  #nodeSelector:
    #workload: monitor
alertmanager:
  enabled: true
  #alertManagerSpec:
    #nodeSelector:
      #workload: monitor
