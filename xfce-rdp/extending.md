Extending the xfce-rdp base image

This document describes how to extend the `xfce-rdp` base image at build time and at container start time.

1) Build-time: installing additional packages

- Approach: Derived images should install additional packages directly in their `Dockerfile`.

  Example:

  ```Dockerfile
  FROM yourbase:tag
  RUN apt-get update && \
      apt-get install -y --no-install-recommends pkg1 pkg2 && \
      rm -rf /var/lib/apt/lists/*
  ```

- Best practices:
  - Combine `apt-get update` and `apt-get install` in a single `RUN` to avoid cache issues.
  - Clean up apt lists after installing to keep image size small.
  - Pin package versions if you need reproducible builds.
  - Document any assumptions about the base image in your derived Dockerfile comments.

2) Runtime: deterministic entrypoint hook runner

- Hook root directory: `/etc/entrypoint.d/`
- Phases (processed in order):
  - `pre`
  - `main`
  - `post`

- Naming convention: scripts must use a three-digit numeric prefix followed by a descriptive name, e.g. `010-setup-home.sh`, `100-configure-audio.sh`, `900-finalize.sh`.
  - Three digits allow room for inserting new scripts between existing ones.

- Execution order and behavior:
  - The entrypoint will process `pre`, then `main`, then `post` directories.
  - Within each directory, scripts are sorted using a natural version sort (`sort -V`) which respects the numeric prefixes.
  - Only executable files (`chmod +x`) are run; non-executable files are ignored with a warning.

- Environment variables controlling behavior:
  - `SKIP_ENTRYPOINT_HOOKS=1` -> skip running all hooks (useful for debugging).
  - `ENTRYPOINT_STRICT` -> if set to `1` (default) the entrypoint exits on first failing hook; if `0` it logs failures and continues.

- Hook script contract:
  - Be executable and idempotent.
  - Log actions to stdout/stderr.
  - Return `0` on success, non-zero on failure.
  - Avoid long-running blocking tasks. If a hook must start a background service, ensure it is supervised properly or backgrounded explicitly.

- Notes about bind mounts and volumes:
  - Consumers may mount files or scripts into `/etc/entrypoint.d/` at runtime. The runner tolerates empty or missing directories and will ignore non-executable files.

- Examples:
  - Add a hook from a derived image at build time:

    ```Dockerfile
    FROM yourbase:tag
    COPY hooks/010-setup-home.sh /etc/entrypoint.d/pre/010-setup-home.sh
    RUN chmod +x /etc/entrypoint.d/pre/010-setup-home.sh
    ```

  - Or provide hooks via a volume at runtime:

    ```sh
    docker run -v $(pwd)/myhooks:/etc/entrypoint.d/main yourimage:tag
    ```

3) Documentation and contract

- Keep hook scripts simple, idempotent and documented.
- Add to your derived image README references to any hooks you add and the numeric prefixes you use so other maintainers can insert scripts in the right place.

