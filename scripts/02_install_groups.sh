#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 02_install_groups.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

if ! [ -f "${INSTALLDIR}/etc/.template_stage2" ]; then
    # shellcheck source=scripts/distribution.sh
    . ${SCRIPTSDIR}/distribution.sh

    prepareChroot "${INSTALLDIR}"
    mountCache "${CACHEDIR}" "${INSTALLDIR}"

    # Standard Gentoo packages to install
    PACKAGES="$(getBasePackagesList "$TEMPLATE_FLAVOR")"

    # Standard Gentoo USE flags
    cp "$(getBaseUseFlags)" "${INSTALLDIR}/etc/portage/package.use/qubes-standard"

    echo "  --> Installing Gentoo packages..."
    echo "    --> Selected packages: ${PACKAGES}"
    chroot "${INSTALLDIR}" /bin/bash -l -c "emerge -b -k ${PACKAGES}"

    touch "${INSTALLDIR}/etc/.template_stage2"
fi