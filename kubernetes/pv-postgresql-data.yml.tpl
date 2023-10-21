---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgdata-${PGINSTANCENAME}
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: ${PGDISKSIZE}
  hostPath:
    path: ${KUBEMOUNTPATH}
