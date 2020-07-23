#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 04_install_qubes.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${SCRIPTSDIR}/distribution.sh

prepareChroot "${INSTALLDIR}"
mountCache "${CACHEDIR}" "${INSTALLDIR}"

# Add Qubes Overlay
setupQubesOverlay "${INSTALLDIR}"

# Qubes Gentoo USE flags
if [ -e "$(getQubesUseFlags "$TEMPLATE_FLAVOR")" ]; then
    cp "$(getQubesUseFlags "$TEMPLATE_FLAVOR")" "${INSTALLDIR}/etc/portage/package.use/qubes"
fi

updateChroot "${INSTALLDIR}"

# Qubes specific packages to install
PACKAGES="$(getQubesPackagesList "$TEMPLATE_FLAVOR")"

if [ -n "${PACKAGES}" ]; then
    echo "  --> Installing Qubes packages..."
    echo "    --> Selected packages: ${PACKAGES}"
    chrootCmd "${INSTALLDIR}" "FEATURES=\"${EMERGE_FEATURES}\" emerge -b ${PACKAGES}"
fi