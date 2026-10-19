#!/usr/bin/env bash
set -euo pipefail

# Start SSH tunnel
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:15432:127.0.0.1:5432 \
  reflex@reflex-lab-2 &

SSH_PID=$!

# Close tunnel when script exits
trap 'kill "$SSH_PID" 2>/dev/null || true' EXIT

# Wait for tunnel to become available
for i in {1..20}; do
  if ! kill -0 "$SSH_PID" 2>/dev/null; then
    echo "SSH tunnel failed"
    exit 1
  fi

  if nc -z 127.0.0.1 15432 2>/dev/null; then
    break
  fi

  sleep 0.25
done

if ! nc -z 127.0.0.1 15432 2>/dev/null; then
  echo "SSH tunnel did not become ready"
  exit 1
fi

# Launch SQLMux
sqlmux
