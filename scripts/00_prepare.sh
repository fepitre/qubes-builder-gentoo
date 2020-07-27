#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

echo "--> Gentoo 00_prepare.sh"

if [ "$VERBOSE" -ge 2 ] || [ "$DEBUG" -gt 0 ]; then
    set -x
fi

if [ -z "$TEMPLATE_FLAVOR" ]; then
    # Currently in Qubes empty flavor means GNOME
    export TEMPLATE_FLAVOR=gnome
fi