#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 02_install_groups.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${SCRIPTSDIR}/distribution.sh

# Mount dev/proc/sys
prepareChroot "${INSTALLDIR}"

# Mount local cache as Portage binpkgs and distfiles
mountCache "${CACHEDIR}" "${INSTALLDIR}"

# Select profile
setPortageProfile "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"

# Standard Gentoo flags
setupBaseFlags "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"

# Ensure to upgrade to python3.10
cat > "${INSTALLDIR}/etc/portage/package.use/python3.10" << EOF
*/* PYTHON_TARGETS: -* python3_10
*/* PYTHON_SINGLE_TARGET: -* python3_10
EOF

# Update Portage
updatePortage "${INSTALLDIR}"

# Ensure chroot is up to date
updateChroot "${INSTALLDIR}"

# Once update is finished with forced python3.10 upgrade remote USE file
rm "${INSTALLDIR}/etc/portage/package.use/python3.10"

# Standard Gentoo packages to install
installBasePackages "${INSTALLDIR}" "${TEMPLATE_FLAVOR}"
