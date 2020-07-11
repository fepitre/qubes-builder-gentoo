#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 09_cleanup.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

echo " --> Cleaning..."
rm -f "${INSTALLDIR}/etc/resolv.conf"
rm -f "${INSTALLDIR}/etc/.template_stage*"

umount "${INSTALLDIR}/var/cache/binpkgs"
umount "${INSTALLDIR}/var/cache/distfiles"
umount "${INSTALLDIR}/var/db/repos/qubes"
rm "${INSTALLDIR}/etc/portage/repos.conf/qubes.conf"