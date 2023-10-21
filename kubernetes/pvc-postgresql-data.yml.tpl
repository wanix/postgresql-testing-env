apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgdata-${PGINSTANCENAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PGDISKSIZE}
