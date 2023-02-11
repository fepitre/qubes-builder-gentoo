#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 01_install_core.sh"

if [ "0$VERBOSE" -ge 2 ] || [ "0$DEBUG" -gt 0 ]; then
    set -x
fi

"${SCRIPTSDIR}/../prepare-chroot-base" "$INSTALLDIR" "$DIST" "$TEMPLATE_FLAVOR"
