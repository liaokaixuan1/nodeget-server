#!/bin/sh
# Hostless sets $PORT; NodeGet Server must listen on it (bind 0.0.0.0).
set -e
PORT="${PORT:-2211}"
CONFIG="/nodeget/config.toml"
mkdir -p /nodeget

if [ ! -f "$CONFIG" ]; then
  cat > "$CONFIG" <<EOF
ws_listener = "0.0.0.0:${PORT}"
server_uuid = "auto_gen"
[logging]
log_filter = "info"
[database]
database_url = "sqlite:///nodeget/nodeget.db?mode=rwc"
EOF
else
  # Keep everything else (notably server_uuid) and only move the port.
  # If ws_listener is absent, append it.
  if grep -q '^ws_listener' "$CONFIG"; then
    sed -i "s|^ws_listener.*|ws_listener = \"0.0.0.0:${PORT}\"|" "$CONFIG"
  else
    printf '\nws_listener = "0.0.0.0:%s"\n' "$PORT" >> "$CONFIG"
  fi
fi

echo "NodeGet Server listening on 0.0.0.0:${PORT} (config: $CONFIG)"
echo "Super Token is printed in the startup logs: grep 'Super Token' in the Hostless runtime logs and save it — it is needed to add this Server in Dashboard."

# Binary name per NodeGet docs: `nodeget-server serve -c config.toml`
if command -v nodeget-server >/dev/null 2>&1; then
  exec nodeget-server serve -c "$CONFIG"
elif [ -x /usr/local/bin/nodeget-server ]; then
  exec /usr/local/bin/nodeget-server serve -c "$CONFIG"
elif [ -x /nodeget/nodeget-server ]; then
  exec /nodeget/nodeget-server serve -c "$CONFIG"
else
  echo "ERROR: nodeget-server binary not found in PATH, /usr/local/bin or /nodeget" >&2
  echo "Check the image contents (ls /usr/local/bin, ls /nodeget) and fix start.sh" >&2
  exit 1
fi
