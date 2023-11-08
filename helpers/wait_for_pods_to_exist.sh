#!/bin/sh
# Wait for Pods with a certain name prefix to exist.
# The wait is over when at least one Pod exist or the max wait time is reached.
#
#   $1 : time to wait for each try
#   $2 : maximum time to wait in seconds
#   $3 : message to send for wait
#   $@ : all options to identify the pod
#
# The command is useful in combination with 'kubectl wait' which can wait for a certain condition,
# but cannot wait for existence.

time_to_wait="$1"
shift
max_wait_time_seconds="$1"
shift
message="$1"
shift
start_time=$(date +%s)
while true; do
  process_time=$(( $(date '+%s') - ${start_time}))
  if [ ${process_time} -gt ${max_wait_time_seconds} ];  then
    echo "Error: Timeout reached to wait the awaited pod(s)"
    exit 1
  fi

  if kubectl get pod $@ --request-timeout "3s" 2>&1 | grep -q "No resources found"; then
    echo "${message}"
    sleep "$time_to_wait"
  else
    break
  fi
done
exit 0
