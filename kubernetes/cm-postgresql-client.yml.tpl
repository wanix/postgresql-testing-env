---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${PGINSTANCENAME}-client-files
data:
  psqlrc: |
    \set PROMPT1 '[${CLOUD_PROVIDER_PROMPT}${ENV_PROMPT}%m] %n@%/%R%#%x '
    \set HISTFILE /pgsql/.psql_history-:DBNAME
