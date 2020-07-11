#!/bin/bash

prepareChroot() {
    INSTALLDIR="$1"

    if [ ! -r "${INSTALLDIR}/dev/zero" ]; then
        mkdir -p "${INSTALLDIR}/dev"
        sudo mount --rbind /dev "${INSTALLDIR}/dev"
    fi
    if [ ! -r "${INSTALLDIR}/proc/cpuinfo" ]; then
        mkdir -p "${INSTALLDIR}/proc"
        sudo mount -t proc proc "${INSTALLDIR}/proc"
    fi
    if [ ! -d "${INSTALLDIR}/sys/dev" ]; then\
        mkdir -p "${INSTALLDIR}/sys"
        sudo mount --bind /sys "${INSTALLDIR}/sys"
    fi

    cp /etc/resolv.conf "${INSTALLDIR}/etc/resolv.conf"
}

mountCache() {
    CACHEDIR="$1"
    INSTALLDIR="$2"

    mkdir -p "${CACHEDIR}/distfiles"
    mkdir -p "${CACHEDIR}/binpkgs"

    mount --bind "${CACHEDIR}/distfiles" "${INSTALLDIR}/var/cache/distfiles"
    mount --bind "${CACHEDIR}/binpkgs" "${INSTALLDIR}/var/cache/binpkgs"
}

mountBuilderOverlay() {
    LOCALREPO="$1"

    mkdir -p "${INSTALLDIR}/var/db/repos/qubes"
    mount --bind "${LOCALREPO}" "${INSTALLDIR}/var/db/repos/qubes"

    # Create/update builder-local overlay
    mkdir -p "${INSTALLDIR}/var/db/repos/qubes/metadata"
    mkdir -p "${INSTALLDIR}/var/db/repos/qubes/profiles"
    echo 'masters = gentoo' > "${INSTALLDIR}/var/db/repos/qubes/metadata/layout.conf"
    echo 'qubes' > "${INSTALLDIR}/var/db/repos/qubes/profiles/repo_name"

    # Register builder-local overlay
    cat > "${INSTALLDIR}/etc/portage/repos.conf/qubes.conf" <<EOF
[qubes]
location = /var/db/repos/qubes
auto-sync = no
EOF
}

getFile() {
    PREFIX="$1"
    SUFFIX="$2"
    TEMPLATE_FLAVOR="$3"
    if [ -n "$TEMPLATE_FLAVOR" ]; then
        FILE="${SCRIPTSDIR}/${PREFIX}_${TEMPLATE_FLAVOR}${SUFFIX}"
        if ! [ -r "$FILE" ]; then
            echo "ERROR: '$FILE' does not exist!"
            exit 1
        fi
    else
        FILE="${SCRIPTSDIR}/${PREFIX}${SUFFIX}"
    fi

    echo "$FILE"
}

getPackagesList() {
    PREFIX="$1"
    TEMPLATE_FLAVOR="$2"

    # Strip comments, then convert newlines to single spaces
    PKGGROUPS="$(sed '/^ *#/d; s/  *#.*//' "$(getFile "$PREFIX" ".list" "${TEMPLATE_FLAVOR}")" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

    echo "${PKGGROUPS}"
}

getBasePackagesList() {
    TEMPLATE_FLAVOR="$1"
    getPackagesList packages "${TEMPLATE_FLAVOR}"
}

getQubesPackagesList() {
    TEMPLATE_FLAVOR="$1"
    getPackagesList packages_qubes "${TEMPLATE_FLAVOR}"
}

getBaseUseFlags() {
    TEMPLATE_FLAVOR="$1"

    getFile packages .use "${TEMPLATE_FLAVOR}"
}

getQubesUseFlags() {
    TEMPLATE_FLAVOR="$1"

    getFile packages_qubes .use "${TEMPLATE_FLAVOR}"
}