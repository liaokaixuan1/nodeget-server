# NodeGet Server for Hostless (free pool: 0.5 vCPU / 1 GiB)
# Use the official image as base instead of building Rust from source:
# a cargo build would likely OOM / time out on 0.5 vCPU / 1 GiB.
# Official image: nodeget/nodeget:latest (nodeget.com/guide/install/docker.html)
# It auto-generates /nodeget/config.toml with ws_listener 0.0.0.0:2211
# and sqlite:///nodeget/nodeget.db?mode=rwc on first start.
# Hostless sets $PORT and requires the app to listen on it, so start.sh
# rewrites ws_listener to 0.0.0.0:$PORT before starting the server.
# NOTE: the binary name `nodeget-server` comes from the NodeGet docs
# (`nodeget-server serve -c config.toml`); verify it in the first build/
# run log — if the image's entrypoint differs, adjust start.sh accordingly.
FROM nodeget/nodeget:latest
WORKDIR /nodeget
COPY start.sh /nodeget/start.sh
RUN chmod +x /nodeget/start.sh
CMD ["sh", "/nodeget/start.sh"]
