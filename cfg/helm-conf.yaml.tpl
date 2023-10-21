# Template to generate a Default conf file
---
image:
  tag: ${PGVERSION}

primary:
  persistence:
    existingClaim: pvc-pgdata-${PGINSTANCENAME}

volumePermissions:
  enabled: true

global:
  postgresql:
    auth:
      postgresPassword: '${PGMAINPASSWORD}'
      username: '${PGUSERNAME}'
      password: '${PGUSERPASSWORD}'
      database: '${PGMAINDB}'
