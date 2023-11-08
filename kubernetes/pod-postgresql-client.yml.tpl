apiVersion: v1
kind: Pod
metadata:
  labels:
    app: infra-psql
    launchedBy: ${USER}
  name: ${PGINSTANCENAME}-client
spec:
  securityContext:
    runAsUser: ${PGUSERUID}
    runAsGroup: ${PGUSERGID}
    fsGroup: ${PGUSERGID}
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
      image: ${PGCONTAINERIMAGE}
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
              name: ${PGINSTANCENAME}-app
              key: password
        - name: PGUSER
          valueFrom:
            secretKeyRef:
              name: ${PGINSTANCENAME}-app
              key: username
        - name: PGDATABASE
          valueFrom:
            secretKeyRef:
              name: ${PGINSTANCENAME}-app
              key: dbname
        - name: PGHOST
          valueFrom:
            secretKeyRef:
              name: ${PGINSTANCENAME}-app
              key: host
        - name: PGPOST
          valueFrom:
            secretKeyRef:
              name: ${PGINSTANCENAME}-app
              key: port
      volumeMounts:
        - name: config-files
          mountPath: /.psqlrc
          subPath: psqlrc
        - name: config-files
          mountPath: /etc/motd
          subPath: motd
        - name: config-files
          mountPath: /.bashrc
          subPath: bashrc
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
