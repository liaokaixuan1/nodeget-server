#!/bin/sh
# NodeGet Server start script for Hostless.
# Hostless sets $PORT; NodeGet Server must listen on it (bind 0.0.0.0).
# Hostless apps run with a READ-ONLY filesystem: only /tmp, /root and
# /app/.cache accept writes, and a restart deletes their files.
# So config + SQLite DB live in /tmp (recreated on each container start).
# The official image entrypoint is NOT used (it writes /nodeget/config.toml
# and fails here); the Dockerfile ENTRYPOINT runs this script directly.
# Consequence (free tier): config, server_uuid and the SQLite DB are
# ephemeral - a container restart regenerates server_uuid and wipes the
# DB. Only a paid Disk (+ verified payment method) would persist them.
set -e

PORT="${PORT:-2211}"
CONFIG="/tmp/config.toml"
DB_URL="sqlite:///tmp/nodeget.db?mode=rwc"

if [ ! -f "$CONFIG" ]; then
  echo "Creating config at $CONFIG (PORT=$PORT)..."
  cat > "$CONFIG" <<EOF
ws_listener = "0.0.0.0:${PORT}"
server_uuid = "auto_gen"

[logging]
log_filter = "info"

[database]
database_url = "${DB_URL}"
EOF
else
  # Keep everything else (notably server_uuid) and only move the port.
  # If ws_listener is absent, append it.
  echo "Config exists, updating ws_listener to 0.0.0.0:${PORT} (keeping server_uuid)..."
  if grep -q '^ws_listener' "$CONFIG"; then
    sed -i "s|^ws_listener.*|ws_listener = \"0.0.0.0:${PORT}\"|" "$CONFIG"
  else
    printf '\nws_listener = "0.0.0.0:%s"\n' "$PORT" >> "$CONFIG"
  fi
fi

echo "NodeGet Server listening on 0.0.0.0:${PORT} (config: $CONFIG, db: /tmp/nodeget.db)"
echo "Super Token is printed in the startup logs: grep 'Super Token' in the Hostless runtime logs and save it - it is the Dashboard login."

# Binary name per NodeGet docs: `nodeget-server serve -c config.toml`
if command -v nodeget-server >/dev/null 2>&1; then
  exec nodeget-server serve -c "$CONFIG"
elif [ -x /usr/local/bin/nodeget-server ]; then
  exec /usr/local/bin/nodeget-server serve -c "$CONFIG"
elif [ -x /nodeget/nodeget-server ]; then
  exec /nodeget/nodeget-server serve -c "$CONFIG"
else
  echo "ERROR: nodeget-server binary not found in PATH, /usr/local/bin or /nodeget" >&2
  exit 1
fi
