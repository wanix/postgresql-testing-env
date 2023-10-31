---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgwatch2-${PGINSTANCENAME}-pg
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 2Gi
  hostPath:
    path: ${KUBEMOUNTPATH}/pgwatch2/pg

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgwatch2-${PGINSTANCENAME}-grafana
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  hostPath:
    path: ${KUBEMOUNTPATH}/pgwatch2/grafana

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-pgwatch2-${PGINSTANCENAME}-config
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 256Mi
  hostPath:
    path: ${KUBEMOUNTPATH}/pgwatch2/config