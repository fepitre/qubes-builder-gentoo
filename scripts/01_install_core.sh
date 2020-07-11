#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 01_install_core.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

if ! [ -f "${INSTALLDIR}/etc/.template_stage1" ]; then
    "${SCRIPTSDIR}/../prepare-chroot-base" "$INSTALLDIR" "$DIST"
    touch "${INSTALLDIR}/etc/.template_stage1"
fi