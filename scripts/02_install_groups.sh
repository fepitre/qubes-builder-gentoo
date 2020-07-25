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
for flag in use accept_keywords
do
    if [ -e "$(getBaseFlags "$TEMPLATE_FLAVOR" "$flag")" ]; then
        mkdir -p "${INSTALLDIR}/etc/portage/package.$flag"
        cp "$(getBaseFlags "$TEMPLATE_FLAVOR" "$flag")" "${INSTALLDIR}/etc/portage/package.$flag/standard"
    fi
done

updateChroot "${INSTALLDIR}"

# Standard Gentoo packages to install
PACKAGES="$(getBasePackagesList "$TEMPLATE_FLAVOR")"

if [ -n "${PACKAGES}" ]; then
    echo "  --> Installing Gentoo packages..."
    echo "    --> Selected packages: ${PACKAGES}"
    chrootCmd "${INSTALLDIR}" "FEATURES=\"${EMERGE_FEATURES}\" emerge ${EMERGE_OPTS} ${PACKAGES}"
fi
