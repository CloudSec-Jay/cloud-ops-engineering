# Authelia Compose Scaffold

This stack is intended to provide an authentication gateway for internal services. The container is bound to `127.0.0.1:9091` and reads its session secret from a Compose secret.

## Status

This is an incomplete scaffold, not a deployable authentication service. The configuration template does not yet define a complete authentication backend, access-control policy, storage provider, or notifier. Confirm the filename and required settings against the selected Authelia release before starting it.

## Prepare and validate

```bash
cd containers/compose/authelia
cp secrets/session_secret.example secrets/session_secret
docker compose -f compose.yml config --quiet
```

Replace the example secret locally with a cryptographically random value. Files under `secrets/` are ignored by Git.

Before deployment, pin the image version, complete the configuration, place Authelia behind a TLS-enabled reverse proxy, validate trusted proxy headers, and test both allowed and denied access paths.
