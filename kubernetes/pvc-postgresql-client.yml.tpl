---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgsql-${PGINSTANCENAME}
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 128Mi
