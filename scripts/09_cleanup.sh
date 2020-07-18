#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 09_cleanup.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

# shellcheck source=scripts/distribution.sh
. ${SCRIPTSDIR}/distribution.sh

echo " --> Cleaning..."
echo '# This file intentionally left blank' > "${INSTALLDIR}/etc/resolv.conf"

rm -f "${INSTALLDIR}/etc/.prepared_base"
rm -f "${INSTALLDIR}/etc/.extracted_stage3"
rm -f "${INSTALLDIR}/etc/.extracted_portage"

umount "${INSTALLDIR}/var/cache/binpkgs" || true
umount "${INSTALLDIR}/var/cache/distfiles" || true

echo " --> Fix permissions"
chrootCmd "${INSTALLDIR}" 'chmod 755 /var/cache/binpkgs'
chrootCmd "${INSTALLDIR}" 'chmod 755 /var/cache/distfiles'
chrootCmd "${INSTALLDIR}" 'chown portage:portage /var/cache/binpkgs'
chrootCmd "${INSTALLDIR}" 'chown portage:portage /var/cache/distfiles'