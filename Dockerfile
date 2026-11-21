# NodeGet Server for Hostless (free pool: 0.5 vCPU / 1 GiB)
# Use the official image as base instead of building Rust from source:
# a cargo build would likely OOM / time out on 0.5 vCPU / 1 GiB.
# Official image: nodeget/nodeget:latest (nodeget.com/guide/install/docker.html)
# Hostless sets $PORT and requires the app to listen on it, so start.sh
# rewrites ws_listener to 0.0.0.0:$PORT before starting the server.
# Hostless apps run with a READ-ONLY filesystem: only /tmp, /root and
# /app/.cache accept writes (restart wipes them). The official image's
# ENTRYPOINT (/usr/local/bin/nodeget-entrypoint) writes /nodeget/config.toml
# and therefore fails here with "Read-only file system" (exit 1).
# So: override ENTRYPOINT to run start.sh directly, and start.sh writes
# config + SQLite DB to /tmp instead of /nodeget.
# Consequence: config, server_uuid and the SQLite DB are ephemeral -
# a container restart regenerates them (free tier has no persistent
# volume without a paid Disk + verified payment method).
FROM nodeget/nodeget:latest

WORKDIR /nodeget

COPY start.sh /nodeget/start.sh
RUN chmod +x /nodeget/start.sh

ENTRYPOINT ["sh", "/nodeget/start.sh"]
