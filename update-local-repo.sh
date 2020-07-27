#!/bin/sh

echo "-> Gentoo update-local-repo.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

INSTALLDIR="$1"
DISTRO="$2"

if [ -n "${GENTOO_OVERLAY}" ]; then
    rsync -a --exclude '.git' --exclude 'profiles' --exclude 'metadata' --delete "${GENTOO_OVERLAY}" "${BUILDER_REPO_DIR}/"
    # WIP: hack for changing overlay location in qubes.eclass
    sed -i "s|QUBES_OVERLAY_DIR=.*|QUBES_OVERLAY_DIR=/tmp/qubes-packages-mirror-repo|" "${BUILDER_REPO_DIR}/eclass/qubes.eclass"
else
    echo "Cannot find GENTOO_OVERLAY. Initializing empty builder-local overlay..."
fi

rm -rf "${BUILDER_REPO_DIR}/metadata" "${BUILDER_REPO_DIR}/profile"
mkdir -p "${BUILDER_REPO_DIR}/metadata" "${BUILDER_REPO_DIR}/profiles"
echo 'masters = gentoo' > "${BUILDER_REPO_DIR}/metadata/layout.conf"
echo 'builder-local' > "${BUILDER_REPO_DIR}/profiles/repo_name"

    cat > "${INSTALLDIR}/etc/portage/repos.conf/builder-local.conf" <<EOF
[builder-local]
location = /tmp/qubes-packages-mirror-repo
auto-sync = no
EOF