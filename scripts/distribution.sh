#!/bin/bash

EMERGE_FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"
EMERGE_OPTS="-b -k --keep-going=y"

prepareChroot() {
    CHROOTDIR="$1"

    if [ ! -r "${CHROOTDIR}/dev/zero" ]; then
        mkdir -p "${CHROOTDIR}/dev"
        sudo mount --rbind /dev "${CHROOTDIR}/dev"
    fi
    if [ "$(stat -f -c '%T' ${CHROOTDIR}/dev/shm 2>/dev/null)" != "tmpfs" ]; then
        mkdir -p "${CHROOTDIR}/dev/shm"
        sudo mount -t tmpfs shm "${CHROOTDIR}/dev/shm"
        sudo chmod 1777 "${CHROOTDIR}/dev/shm"
    fi
    if [ ! -r "${CHROOTDIR}/proc/cpuinfo" ]; then
        mkdir -p "${CHROOTDIR}/proc"
        sudo mount -t proc proc "${CHROOTDIR}/proc"
    fi
    if [ ! -d "${CHROOTDIR}/sys/dev" ]; then\
        mkdir -p "${CHROOTDIR}/sys"
        sudo mount --bind /sys "${CHROOTDIR}/sys"
    fi
    cp /etc/resolv.conf "${CHROOTDIR}/etc/resolv.conf"
}

chrootCmd() {
    CHROOTDIR="$1"
    shift
    CMD="$*"

    chroot "${CHROOTDIR}" env -i /bin/bash -l -c "rm -f /etc/ld.so.cache && ldconfig && env-update"
    chroot "${CHROOTDIR}" env -i /bin/bash -l -c "source /etc/profile && $CMD"
}

updateChroot() {
    CHROOTDIR="$1"

    chrootCmd "${CHROOTDIR}" "FEATURES=\"${EMERGE_FEATURES}\" emerge ${EMERGE_OPTS} --update --deep --newuse --changed-use --with-bdeps=y @world"
}

mountCache() {
    CACHEDIR="$1"
    CHROOTDIR="$2"

    mkdir -p "${CACHEDIR}/distfiles"
    mkdir -p "${CACHEDIR}/binpkgs"

    mount --bind "${CACHEDIR}/distfiles" "${CHROOTDIR}/var/cache/distfiles"
    mount --bind "${CACHEDIR}/binpkgs" "${CHROOTDIR}/var/cache/binpkgs"
}

setupQubesOverlay() {
    CHROOTDIR="$1"
    rm -rf "${CHROOTDIR}/var/db/repos/qubes"
    mkdir -p "${CHROOTDIR}/var/db/repos/qubes"
    cat > "${CHROOTDIR}/etc/portage/repos.conf/qubes.conf" <<EOF
[qubes]
location = /var/db/repos/qubes
sync-uri = https://github.com/fepitre/qubes-gentoo.git
sync-type = git
sync-git-verify-commit-signature = true
sync-openpgp-key-path = /usr/share/openpgp-keys/frederic-pierret.asc
sync-openpgp-key-refresh = false
auto-sync = yes
EOF

    # Add @fepitre's key
    cp "${SCRIPTSDIR}/../keys/frederic-pierret.asc" "${CHROOTDIR}/usr/share/openpgp-keys/frederic-pierret.asc"

    # Add Qubes overlay
    chrootCmd "${CHROOTDIR}" "emaint sync -r qubes"
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