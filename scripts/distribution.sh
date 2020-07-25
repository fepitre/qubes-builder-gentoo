#!/bin/bash

EMERGE_FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"
EMERGE_OPTS="-b -k --keep-going=y -n"

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

    chroot "${CHROOTDIR}" env -i /bin/bash -l -c "env-update"
    chroot "${CHROOTDIR}" env -i /bin/bash -l -c "source /etc/profile && $CMD"
}

updateChroot() {
    CHROOTDIR="$1"
    chrootCmd "${CHROOTDIR}" "emaint -a sync"
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
    BASEDIR="$1"
    PREFIX="$2"
    SUFFIX="$3"
    TEMPLATE_FLAVOR="$4"

    FILE="${BASEDIR}/${PREFIX}${TEMPLATE_FLAVOR}${SUFFIX}"

    echo "$FILE"
}

getPackagesList() {
    PREFIX="$1"
    TEMPLATE_FLAVOR="$2"

    # Strip comments, then convert newlines to single spaces
    FILE="$(getFile "${SCRIPTSDIR}" "$PREFIX" ".list" "${TEMPLATE_FLAVOR}")"
    if [ ! -e "$FILE" ]; then
        echo "Cannot find '$FILE'!"
        exit 1
    fi
    PKGGROUPS="$(sed '/^ *#/d; s/  *#.*//' "$FILE" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

    echo "${PKGGROUPS}"
}

getBasePackagesList() {
    # Default flavor is 'gnome' without explicit TEMPLATE_FLAVOR value
    TEMPLATE_FLAVOR="${1:-gnome}"
    getPackagesList packages_ "${TEMPLATE_FLAVOR}"
}

getQubesPackagesList() {
    TEMPLATE_FLAVOR="${1:-gnome}"
    getPackagesList packages_qubes_ "${TEMPLATE_FLAVOR}"
}

getBaseFlags() {
    TEMPLATE_FLAVOR="${1:-gnome}"
    FLAGS="$2"

    getFile "${SCRIPTSDIR}/package.$FLAGS/" "" "" "${TEMPLATE_FLAVOR}"
}

getQubesFlags() {
    TEMPLATE_FLAVOR="${1:-gnome}"
    FLAGS="$2"

    getFile "${SCRIPTSDIR}/package.$FLAGS/" "" "-qubes" "${TEMPLATE_FLAVOR}"
}