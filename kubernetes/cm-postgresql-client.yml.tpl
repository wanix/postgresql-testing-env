---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${PGINSTANCENAME}-client-files
data:
  psqlrc: |
    \set PROMPT1 '[${CLOUD_PROVIDER_PROMPT}${ENV_PROMPT}%m] %n@%/%R%#%x '
    \set HISTFILE /pgsql/.psql_history-:DBNAME
  motd: |
    ----------------------------------------------------------------
          ${PGINSTANCENAME}-client
    ----------------------------------------------------------------
      You can now use PostgreSQL tools as:
       - psql
       - pgdump / pgrestore
      
      case minikube, share files with this pod using on your laptop:
        cp path/to/file ${KSSHAREDSPACE}/psql/file
      then you will be able to use /pgsql/file from this pod
      
      case external K8s to copy file to this pod, use the following command from
        your laptop:
      kubectl cp path/to/file "${KSNAMESPACE}/${PGINSTANCENAME}-client:/pgsql/file"
    ----------------------------------------------------------------
  bashrc: |
    cat /etc/motd
    export PS1="UID-${PGUSERUID}@\\h:\\w\\$ "
