apiVersion: v1
kind: Pod
metadata:
  labels:
    app: infra-psql
    launchedBy: ${USER}
  name: ${PGINSTANCENAME}-client
spec:
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
      resources:
        limits:
          cpu: 600m
          memory: 1Gi
        requests:
          cpu: 100m
          memory: 64Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30