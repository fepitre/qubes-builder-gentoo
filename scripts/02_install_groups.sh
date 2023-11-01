#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 02_install_groups.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${TEMPLATE_CONTENT_DIR}/distribution.sh

# Mount dev/proc/sys
prepareChroot "${INSTALL_DIR}"

# Mount local cache as Portage binpkgs and distfiles
mountCache "${CACHE_DIR}" "${INSTALL_DIR}"

# Select profile
setPortageProfile "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"

# Standard Gentoo flags
setupBaseFlags "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"

# Update Portage
updatePortage "${INSTALL_DIR}"

# Ensure chroot is up to date
updateChroot "${INSTALL_DIR}"

# Standard Gentoo packages to install
installBasePackages "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"
