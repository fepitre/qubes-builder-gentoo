#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 04_install_qubes.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

if ! [ -f "${INSTALLDIR}/etc/.template_stage4" ]; then
    # shellcheck source=scripts/distribution.sh
    . ${SCRIPTSDIR}/distribution.sh

    LOCALREPO="$(readlink -f "pkgs-for-template/$DIST/pkgs")"

    prepareChroot "${INSTALLDIR}"
    mountCache "${CACHEDIR}" "${INSTALLDIR}"

    # Mount builder-local overlay
    mountBuilderOverlay "${LOCALREPO}" "${INSTALLDIR}"

    # Qubes specific packages to install
    PACKAGES="$(getQubesPackagesList "$TEMPLATE_FLAVOR")"

    echo "  --> Installing Qubes packages..."
    echo "    --> Selected packages: ${PACKAGES}"
    chroot "${INSTALLDIR}" /bin/bash -l -c "emerge -b -k ${PACKAGES}"

    touch "${INSTALLDIR}/etc/.template_stage4"
fi