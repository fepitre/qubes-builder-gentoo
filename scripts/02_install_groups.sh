#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 02_install_groups.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${SCRIPTSDIR}/distribution.sh

prepareChroot "${INSTALLDIR}"
mountCache "${CACHEDIR}" "${INSTALLDIR}"

if [ -z "$TEMPLATE_FLAVOR" ] || [ "$TEMPLATE_FLAVOR" == "xfce" ] || [ "$TEMPLATE_FLAVOR" == "gnome" ]; then
    # Select desktop/gnome/systemd profile
    chrootCmd "${INSTALLDIR}" "eselect profile set default/linux/amd64/17.1/desktop/gnome/systemd"
fi

# Standard Gentoo flags
setupBaseFlags "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"

# Ensure chroot is up to date
updateChroot "${INSTALLDIR}"

# Standard Gentoo packages to install
installBasePackages "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"
