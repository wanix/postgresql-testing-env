apiVersion: v1
kind: Pod
metadata:
  labels:
    app: infra-psql
    launchedBy: ${USER}
  name: ${PGINSTANCENAME}-client
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    runAsNonRoot: true
  volumes:
    - name: config-files
      configMap:
        name: ${PGINSTANCENAME}-client-files
    - name: psql-storage
      persistentVolumeClaim:
        claimName: pvc-pgsql-${PGINSTANCENAME}
  containers:
    - name: postgresql-client
      image: bitnami/postgresql:${PGVERSION}
      imagePullPolicy: IfNotPresent
      command:
        - /bin/bash
      args:
        - -c
        - sleep 12h
      env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: ${PGINSTANCENAME}
              key: postgres-password
        - name: PGUSER
          value: postgres
      volumeMounts:
        - name: config-files
          mountPath: /.psqlrc
          subPath: psqlrc
        - name: psql-storage
          mountPath: /pgsql
      resources:
        limits:
          cpu: 600m
          memory: 1Gi
        requests:
          cpu: 100m
          memory: 64Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
