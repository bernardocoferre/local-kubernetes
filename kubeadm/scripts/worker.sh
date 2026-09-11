#!/bin/bash

set -euo pipefail

JOIN_COMMAND=/vagrant/generated/join-command.sh
TIMEOUT_SECONDS=300

elapsed=0

until [ -f "$JOIN_COMMAND" ]; do
  if [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]; then
    echo "ERROR: $JOIN_COMMAND never appeared after ${TIMEOUT_SECONDS}s -- master.sh likely failed" >&2
    exit 1
  fi
  echo "Waiting for join-command.sh..."
  sleep 5
  elapsed=$((elapsed + 5))
done

bash "$JOIN_COMMAND"
