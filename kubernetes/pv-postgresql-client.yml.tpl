---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgsql-${PGINSTANCENAME}
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 128Mi
  hostPath:
    path: ${KUBEMOUNTPATH}/psql
