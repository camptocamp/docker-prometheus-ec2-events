#!/bin/sh

if [ -z "${PUSHGATEWAY_URL}" ]; then
  echo "Missing PUSHGATEWAY_URL envvar, exiting."
  exit 1
else
  INSTANCE="$(curl -fsS -m 5 http://169.254.169.254/latest/meta-data/public-hostname || hostname -f)"
  PUSHGATEWAY_URL="${PUSHGATEWAY_URL}/metrics/job/ec2_events/instance/${INSTANCE}"
fi

echo "Checking for scheduled maintenance events."

curl -fsS -m 5 http://169.254.169.254/latest/meta-data/events/maintenance/ > /dev/null
if [ $? -ne 0 ]; then
  # no /events section found in meta-data, *assuming* this means there are none.
  SCHEDULED=0
  EXITSTATUS=1
else
  EXITSTATUS=0
  SCHEDULED="$(curl -s -m 5 http://169.254.169.254/latest/meta-data/events/maintenance/scheduled | jq '. | length')"
  if [ $? -ne 0 ]; then
    EXITSTATUS=1
  fi
fi

echo "Figured out we have $SCHEDULED scheduled maintenance events."

cat <<EOF | curl -sS -m 30 --data-binary @- "$PUSHGATEWAY_URL"
ec2_events_last_run_exit_status $EXITSTATUS
ec2_events_last_run_time $(date +%s)
ec2_events_scheduled_maintenance_count $SCHEDULED
EOF

echo "Submission to '${PUSHGATEWAY_URL}' ended with exit status '$?'."
