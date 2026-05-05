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
    alertmanager: false
    etcd: false
    configReloaders: false
    general: false
    k8s: true
    kubeApiserver: false
    kubeApiserverAvailability: false
    kubeApiserverSlos: false
    kubelet: true
    kubeProxy: false
    kubePrometheusGeneral: false
    kubePrometheusNodeRecording: false
    kubernetesApps: false
    kubernetesResources: false
    kubernetesStorage: false
    kubernetesSystem: false
    kubeScheduler: false
    kubeStateMetrics: false
    network: false
    node: true
    nodeExporterAlerting: false
    nodeExporterRecording: true
    prometheus: false
    prometheusOperator: false

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
  sidecar:
    dashboards:
      enabled: true
  #nodeSelector:
    #workload: monitor
alertmanager:
  enabled: true
  #alertManagerSpec:
    #nodeSelector:
      #workload: monitor
