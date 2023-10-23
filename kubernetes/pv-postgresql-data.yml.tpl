---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgdata-${PGINSTANCENAME}
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: ${PGDISKSIZE}
  hostPath:
    path: ${KUBEMOUNTPATH}
