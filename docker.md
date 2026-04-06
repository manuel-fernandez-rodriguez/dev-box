# Build
```bash
docker build -t dev-box .
```
# Run
Provide a JSON runtime configuration object via a Docker secret (recommended)
or the `RUNTIME_CONFIG` environment variable. The object must contain a
top-level `userCredentials` array where each element contains `username`,
`password` and, optionally `sudo` (boolean, default: false).

Example runtime config JSON:

```json
{"userCredentials":[{"username":"alice","password":"alicepw","sudo":true},
 {"username":"bob","password":"bobpw"}]}
```

Preferred (secure) — provide runtime config JSON as a Docker secret (Swarm):
```bash
echo '{"userCredentials":[{"username":"developer","password":"s3cr3t","sudo":true}]}' > runtime_config.json
docker secret create runtime_config runtime_config.json
docker service create --name dev-box --secret runtime_config --publish 33890:3389 dev-box:latest
```

Single-host (recommended over plain env) — bind-mount a read-only file into /run/secrets:
```bash
echo '{"userCredentials":[{"username":"developer","password":"s3cr3t","sudo":true}]}' > runtime_config.json
docker run -v "$(pwd)/runtime_config.json:/run/secrets/runtime_config:ro" \
  -p 33890:3389 --shm-size=1g  -d --name dev-box dev-box:latest
```

Less secure — provide runtime config JSON via an environment variable (visible in inspect):
```bash
docker run -e RUNTIME_CONFIG='{"userCredentials":[{"username":"developer","password":"s3cr3t","sudo":true}]}' -p 33890:3389 \
  --shm-size=1g -d --name dev-box dev-box:latest
```

Notes:
- Prefer Docker secrets or a read-only file mount to avoid leaking credentials.

## Persisting home directory
```
# Create a named volume and mount it at /home so user homes persist across
# container restarts. The entrypoint will only chown the volume if ownership
# doesn't match the created user's UID.
docker volume create devbox-home
docker run -v devbox-home:/home -v "$(pwd)/runtime_config.json:/run/secrets/runtime_config:ro" \
  -p 33890:3389 --shm-size=1g -d --name dev-box dev-box:latest
```

Note that, even if not mounting a volume, the volume will still be created as an unnamed volume.
c# DevKit extension can take a fair amount of space (500MB+), so once the container has been created once,
the volume can be found with `docker volume ls` and removed with `docker volume rm <volume_name>` if you want to save space.

