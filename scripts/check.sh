#!/bin/sh
# Check the layouts and the artwork with the plugin's device_view_check command.
# The plugin and devicetype-library commits are the pins/ entries of the index.
# Set DOCKER_RUN_ARGS for extra "docker run" options, for example a proxy.
# The script splits DOCKER_RUN_ARGS at spaces.
set -eu
cd "$(dirname "$0")/.."

NETBOX_IMAGE=netboxcommunity/netbox:v4.7.4
CACHE=.cache

pin() {
  commit=$(git ls-files --stage "pins/$1" | cut -d' ' -f2)
  [ -n "$commit" ] || { echo "pins/$1 is not in the index." >&2; exit 1; }
  echo "$commit"
}
url() { git config -f .gitmodules "submodule.pins/$1.url" | sed 's/\.git$//'; }

plugin_commit=$(pin netbox-device-view)
types_commit=$(pin devicetype-library)
types="$CACHE/devicetype-library-$types_commit"

# Only the type files: the full devicetype-library has about 1 GB of images.
if [ ! -d "$types" ]; then
  rm -rf "$types.tmp"
  git init -q "$types.tmp"
  git -C "$types.tmp" remote add origin "$(url devicetype-library)"
  git -C "$types.tmp" sparse-checkout set --no-cone /device-types/ /module-types/
  git -C "$types.tmp" fetch -q --depth 1 --filter=blob:none origin "$types_commit"
  git -C "$types.tmp" checkout -q FETCH_HEAD
  mv "$types.tmp" "$types"
fi

# shellcheck disable=SC2086
docker run --rm ${DOCKER_RUN_ARGS:-} \
  -v "$PWD:/library:ro" -v "$PWD/$types:/devicetype-library:ro" \
  -e PLUGIN="netbox-device-view @ $(url netbox-device-view)/archive/$plugin_commit.tar.gz" \
  -e SECRET_KEY=check-only-not-a-secret-0123456789abcdefghijklmnopqrstuv \
  "$NETBOX_IMAGE" sh -c '
    uv pip install -q --python /opt/netbox/venv/bin/python "$PLUGIN" &&
    echo "PLUGINS = [\"netbox_device_view\"]" > /etc/netbox/config/plugins.py &&
    /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py device_view_check \
      /library --device-types /devicetype-library'
