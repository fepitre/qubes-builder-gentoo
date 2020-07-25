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

# Qubes Gentoo flags
for flag in use accept_keywords
do
    if [ -e "$(getQubesFlags "$TEMPLATE_FLAVOR" "$flag")" ]; then
        mkdir -p "${INSTALLDIR}/etc/portage/package.$flag"
        cp "$(getQubesFlags "$TEMPLATE_FLAVOR" "$flag")" "${INSTALLDIR}/etc/portage/package.$flag/qubes"
    fi
done

updateChroot "${INSTALLDIR}"

# Qubes specific packages to install
PACKAGES="$(getQubesPackagesList "$TEMPLATE_FLAVOR")"

if [ -n "${PACKAGES}" ]; then
    echo "  --> Installing Qubes packages..."
    echo "    --> Selected packages: ${PACKAGES}"
    chrootCmd "${INSTALLDIR}" "FEATURES=\"${EMERGE_FEATURES}\" emerge ${EMERGE_OPTS} ${PACKAGES}"
fi