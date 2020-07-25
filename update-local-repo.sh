#!/bin/sh

echo "-> Gentoo update-local-repo.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

rm -rf "${BUILDER_REPO_DIR}/metadata"
rm -rf "${BUILDER_REPO_DIR}/profiles"

rsync -a --exclude '.git' --exclude 'profiles' --exclude 'metadata' "${GENTOO_OVERLAY}" "${BUILDER_REPO_DIR}/"

# WIP: hack for changing overlay location in qubes.eclass
sed -i "s|QUBES_OVERLAY_DIR=.*|QUBES_OVERLAY_DIR=/tmp/qubes-packages-mirror-repo|" "${BUILDER_REPO_DIR}/eclass/qubes.eclass"