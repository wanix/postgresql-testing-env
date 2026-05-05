---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgsql-${PGINSTANCENAME}
spec:
  storageClassName: ${PGSTORAGECLASS}
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 128Mi
  hostPath:
    path: ${KUBEMOUNTPATH}/psql
