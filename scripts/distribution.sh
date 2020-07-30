#!/bin/bash

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

    /usr/sbin/chroot "${CHROOTDIR}" env -i /bin/bash -l -c "env-update"
    /usr/sbin/chroot "${CHROOTDIR}" env -i /bin/bash -l -c "source /etc/profile && $CMD"
}

updateChroot() {
    CHROOTDIR="$1"
    chrootCmd "${CHROOTDIR}" "emerge ${EMERGE_OPTS} --update --deep --newuse --changed-use --with-bdeps=y @world"
}

mountCache() {
    CACHEDIR="$1"
    CHROOTDIR="$2"

    mkdir -p "${CACHEDIR}/distfiles"
    mkdir -p "${CACHEDIR}/binpkgs"

    if mountpoint -q "${CHROOTDIR}/var/cache/distfiles"; then
        umount "${CHROOTDIR}/var/cache/distfiles"
    fi
    if mountpoint -q "${CHROOTDIR}/var/cache/binpkgs"; then
        umount "${CHROOTDIR}/var/cache/binpkgs"
    fi
    mount --bind "${CACHEDIR}/distfiles" "${CHROOTDIR}/var/cache/distfiles"
    mount --bind "${CACHEDIR}/binpkgs" "${CHROOTDIR}/var/cache/binpkgs"
}

getFile() {
    BASEDIR="$1"
    PREFIX="$2"
    SUFFIX="$3"
    FLAVOR="$4"

    FILE="${BASEDIR}/${PREFIX}${FLAVOR}${SUFFIX}"

    echo "$FILE"
}

getPackagesList() {
    PREFIX="$1"
    FLAVOR="$2"

    # Strip comments, then convert newlines to single spaces
    FILE="$(getFile "${SCRIPTSDIR}" "$PREFIX" ".list" "${FLAVOR}")"
    if [ ! -e "$FILE" ]; then
        echo "Cannot find '$FILE'!"
        exit 1
    fi
    PKGGROUPS="$(sed '/^ *#/d; s/  *#.*//' "$FILE" | sed ':a;N;$!ba; s/\n/ /g; s/  */ /g')"

    echo "${PKGGROUPS}"
}

getBasePackagesList() {
    FLAVOR="${1:-gnome}"
    getPackagesList packages_ "${FLAVOR}"
}

getQubesPackagesList() {
    FLAVOR="${1:-gnome}"
    getPackagesList packages_qubes_ "${FLAVOR}"
}

getBaseFlags() {
    FLAVOR="${1:-gnome}"
    FLAGS="$2"

    getFile "${SCRIPTSDIR}/package.$FLAGS/" "" "" "${FLAVOR}"
}

getQubesFlags() {
    FLAVOR="${1:-gnome}"
    FLAGS="$2"

    getFile "${SCRIPTSDIR}/package.$FLAGS/" "" "-qubes" "${FLAVOR}"
}

setupBaseFlags() {
    CHROOTDIR="$1"
    FLAVOR="${2:-gnome}"
    for flag in use mask accept_keywords
    do
        if [ -e "$(getBaseFlags "$FLAVOR" "$flag")" ]; then
            mkdir -p "${CHROOTDIR}/etc/portage/package.$flag"
            cp "$(getBaseFlags "$FLAVOR" "$flag")" "${CHROOTDIR}/etc/portage/package.$flag/standard"
        fi
    done
}

setupQubesFlags() {
    CHROOTDIR="$1"
    FLAVOR="${2:-gnome}"
    for flag in use mask accept_keywords
    do
        if [ -e "$(getQubesFlags "$FLAVOR" "$flag")" ]; then
            mkdir -p "${CHROOTDIR}/etc/portage/package.$flag"
            cp "$(getQubesFlags "$FLAVOR" "$flag")" "${CHROOTDIR}/etc/portage/package.$flag/qubes"
        fi
    done
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
sync-openpgp-key-path = /usr/share/openpgp-keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc
sync-openpgp-key-refresh = false
auto-sync = yes
EOF

    # Add @fepitre's key
    cp "${SCRIPTSDIR}/../keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc" "${CHROOTDIR}/usr/share/openpgp-keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc"

    # Add Qubes overlay
    chrootCmd "${CHROOTDIR}" "emaint sync -r qubes"
}

installBasePackages() {
    CHROOTDIR="$1"
    FLAVOR="${2:-gnome}"

    PACKAGES="$(getBasePackagesList "$FLAVOR")"
    if [ -n "${PACKAGES}" ]; then
        echo "  --> Installing Gentoo packages..."
        echo "    --> Selected packages: ${PACKAGES}"
        chrootCmd "${CHROOTDIR}" "emerge ${EMERGE_OPTS} ${PACKAGES}"
    fi
}

installQubesPackages() {
    CHROOTDIR="$1"
    FLAVOR="${2:-gnome}"

    PACKAGES="$(getQubesPackagesList "$FLAVOR")"
    if [ -n "${PACKAGES}" ]; then
        echo "  --> Installing Qubes packages..."
        echo "    --> Selected packages: ${PACKAGES}"
        chrootCmd "${CHROOTDIR}" "emerge ${EMERGE_OPTS} ${PACKAGES}"
    fi
}

setPortageProfile() {
    CHROOTDIR="$1"
    FLAVOR="${2:-gnome}"
    if [ "$FLAVOR" == "xfce" ] || [ "$FLAVOR" == "gnome" ]; then
        # Select desktop/gnome/systemd profile
        chrootCmd "${CHROOTDIR}" "eselect profile set default/linux/amd64/17.1/desktop/gnome/systemd"
    else
        # Select default systemd profile
        chrootCmd "${CHROOTDIR}" "eselect profile set default/linux/amd64/17.1/systemd"
    fi
}