apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgdata-${PGINSTANCENAME}
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PGDISKSIZE}
