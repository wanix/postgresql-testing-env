---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgwatch2-${PGINSTANCENAME}-pg
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgwatch2-${PGINSTANCENAME}-grafana
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-pgwatch2-${PGINSTANCENAME}-config
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 256Mi
