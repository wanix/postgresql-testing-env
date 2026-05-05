---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgdata-${PGINSTANCENAME}-${PGNODE}
spec:
  storageClassName: ${PGSTORAGECLASS}
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: ${PGDISKSIZE}
  hostPath:
    path: ${KUBEMOUNTPATH}/postgresql/data-node-${PGNODE}
