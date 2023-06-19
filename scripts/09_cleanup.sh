#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 09_cleanup.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${TEMPLATE_CONTENT_DIR}/distribution.sh

echo " --> Cleaning..."
echo '# This file intentionally left blank' > "${INSTALL_DIR}/etc/resolv.conf"

rm -f "${INSTALL_DIR}/etc/.prepared_base"
rm -f "${INSTALL_DIR}/etc/.extracted_stage3"
rm -f "${INSTALL_DIR}/etc/.extracted_portage"

umount "${INSTALL_DIR}/var/cache/binpkgs" || true
umount "${INSTALL_DIR}/var/cache/distfiles" || true

# If exists, remove PORTAGE_BINHOST and use of binpkg
sed -i "/PORTAGE_BINHOST=/d" "${INSTALL_DIR}/etc/portage/make.conf"
sed -i '/FEATURES="$FEATURES getbinpkg"/d' "${INSTALL_DIR}/etc/portage/make.conf"

echo " --> Fix permissions"
chrootCmd "${INSTALL_DIR}" 'chmod 755 /var/cache/binpkgs'
chrootCmd "${INSTALL_DIR}" 'chmod 755 /var/cache/distfiles'
chrootCmd "${INSTALL_DIR}" 'chown portage:portage /var/cache/binpkgs'
chrootCmd "${INSTALL_DIR}" 'chown portage:portage /var/cache/distfiles'
