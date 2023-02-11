#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 04_install_qubes.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${SCRIPTSDIR}/distribution.sh

# Mount dev/proc/sys
prepareChroot "${INSTALLDIR}"

# Mount local cache as Portage binpkgs and distfiles
mountCache "${CACHEDIR}" "${INSTALLDIR}"

# Add Qubes Overlay
setupQubesOverlay "${INSTALLDIR}" "${RELEASE}"

# Standard Gentoo flags: updates base root image flags
setupBaseFlags "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"

# Qubes Gentoo flags
setupQubesFlags "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"

# Ensure chroot is up to date
updateChroot "${INSTALLDIR}"

# Qubes specific packages to install
installQubesPackages "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"
