# code-server Compose Example

This local-only stack runs code-server on `127.0.0.1:8080` and mounts the current project plus the host user's `.local` and `.config` directories.

## Run locally

```bash
cd containers/compose/code-server
export UID="$(id -u)"
export GID="$(id -g)"
export USER="$(id -un)"
docker compose -f compose.yml config --quiet
docker compose -f compose.yml up -d
```

## Security considerations

- The host configuration mounts may expose credentials or application settings to the container. Replace them with narrower mounts whenever possible.
- Keep the port bound to loopback and use authenticated TLS access for any remote connection.
- Pin the image to a reviewed version or digest before shared use.
- Review file ownership because the container runs with the supplied host UID and GID.

This is a developer workstation convenience, not a production service definition.
