---
############################################################################
# https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg
############################################################################

#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Default values for CloudNativePG.
# This is a YAML-formatted file.
# Please declare variables to be passed to your templates.

replicaCount: 1

image:
  repository: ghcr.io/cloudnative-pg/cloudnative-pg
  pullPolicy: IfNotPresent
  # -- Overrides the image tag whose default is the chart appVersion.
  tag: ""

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

crds:
  # -- Specifies whether the CRDs should be created when installing the chart.
  create: true

# -- The webhook configuration.
webhook:
  port: 9443
  mutating:
    create: true
    failurePolicy: Fail
  validating:
    create: true
    failurePolicy: Fail
  livenessProbe:
    initialDelaySeconds: 3
  readinessProbe:
    initialDelaySeconds: 3

# -- Operator configuration.
config:
  # -- Specifies whether the secret should be created.
  create: true
  # -- The name of the configmap/secret to use.
  name: cnpg-controller-manager-config
  # -- Specifies whether it should be stored in a secret, instead of a configmap.
  secret: false
  # -- The content of the configmap/secret, see
  # https://cloudnative-pg.io/documentation/current/operator_conf/#available-options
  # for all the available options.
  data: {}
  # INHERITED_ANNOTATIONS: categories
  # INHERITED_LABELS: environment, workload, app
  # WATCH_NAMESPACE: namespace-a,namespace-b

# -- Additinal arguments to be added to the operator's args list.
additionalArgs: []

serviceAccount:
  # -- Specifies whether the service account should be created.
  create: true
  # -- The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template.
  name: ""

rbac:
  # -- Specifies whether ClusterRole and ClusterRoleBinding should be created.
  create: true
  # -- Aggregate ClusterRoles to Kubernetes default user-facing roles.
  # Ref: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles
  aggregateClusterRoles: false

# -- Annotations to be added to all other resources.
commonAnnotations: {}
# -- Annotations to be added to the pod.
podAnnotations: {}
# -- Labels to be added to the pod.
podLabels: {}

# -- Container Security Context.
containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsUser: 10001
  runAsGroup: 10001
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - "ALL"

# -- Security Context for the whole pod.
podSecurityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
  # fsGroup: 2000

# -- Priority indicates the importance of a Pod relative to other Pods.
priorityClassName: ""

service:
  type: ClusterIP
  # -- DO NOT CHANGE THE SERVICE NAME as it is currently used to generate the certificate
  # and can not be configured
  name: cnpg-webhook-service
  port: 443

resources:
  # If you want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  limits:
    cpu: 100m
    memory: 200Mi
  requests:
    cpu: 100m
    memory: 100Mi

# -- Nodeselector for the operator to be installed.
nodeSelector: {}

# -- Tolerations for the operator to be installed.
tolerations: []

# -- Affinity for the operator to be installed.
affinity: {}

monitoring:
  # -- Specifies whether the monitoring should be enabled. Requires Prometheus Operator CRDs.
  podMonitorEnabled: true
  grafanaDashboard:
    create: true
    # -- Allows overriding the namespace where the ConfigMap will be created, defaulting to the same one as the Release.
    namespace: "monitoring"
    # -- The name of the ConfigMap containing the dashboard.
    configMapName: "cnpg-grafana-dashboard"
    # -- Label that ConfigMaps should have to be loaded as dashboards.  DEPRECATED: Use labels instead.
    sidecarLabel: "grafana_dashboard"
    # -- Label value that ConfigMaps should have to be loaded as dashboards.  DEPRECATED: Use labels instead.
    sidecarLabelValue: "1"
    # -- Labels that ConfigMaps should have to get configured in Grafana.
    labels: {}
    # -- Annotations that ConfigMaps can have to get configured in Grafana.
    annotations: {}
