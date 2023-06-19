#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 04_install_qubes.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${TEMPLATE_CONTENT_DIR}/distribution.sh

# Mount dev/proc/sys
prepareChroot "${INSTALL_DIR}"

# Mount local cache as Portage binpkgs and distfiles
mountCache "${CACHE_DIR}" "${INSTALL_DIR}"

# Add Qubes Overlay
setupQubesOverlay "${INSTALL_DIR}" "${RELEASE}"

# Standard Gentoo flags: updates base root image flags
setupBaseFlags "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"

# Qubes Gentoo flags
setupQubesFlags "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"

# Ensure chroot is up to date
updateChroot "${INSTALL_DIR}"

# Qubes specific packages to install
installQubesPackages "${INSTALL_DIR}" "${TEMPLATE_FLAVOR}"
