#!/usr/bin/env bash
set -e

# Entrypoint
# USERS_CREDENTIALS must be provided either
# via /run/secrets/users_credentials or the
# USERS_CREDENTIALS environment variable (JSON array).


# shellcheck source=src/entrypoint_helpers.sh
. "$(dirname "$0")/entrypoint_helpers.sh"

# Prepare temp paths
USERS_LIST=""
TMP_JSON="/tmp/users_credentials.json.$$"
TMP_ITEMS="/tmp/users_items.$$"

# Load and validate USERS_CREDENTIALS and store into $TMP_JSON
load_users_json "$TMP_JSON" || exit 1

# Iterate without a pipe to avoid subshell
jq -c '.[]' "$TMP_JSON" > "$TMP_ITEMS" 2>/dev/null || true

while read -r u; do
    [ -n "$u" ] || continue
    uname=$(echo "$u" | jq -r '.username // empty')
    upw=$(echo "$u" | jq -r '.password // empty')
    usudo=$(echo "$u" | jq -r '.sudo // false')
    if [ -z "$uname" ]; then
        echo "[entrypoint] Skipping user entry with no username" >&2
        continue
    fi
    create_user "$uname" "$upw" "$usudo"
    USERS_LIST="$USERS_LIST $uname"
done < "$TMP_ITEMS"

# cleanup temp files
rm -f "$TMP_JSON" "$TMP_ITEMS" 2>/dev/null || true

# If no args provided, run the default xrdp startup command
if [ $# -eq 0 ]; then  
    exec /bin/bash -lc "mkdir -p /run/dbus && dbus-daemon --system --fork || true; /usr/sbin/xrdp-sesman --nodaemon & /usr/sbin/xrdp --nodaemon"
else
    exec "$@"
fi
