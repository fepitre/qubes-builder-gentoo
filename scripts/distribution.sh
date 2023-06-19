#!/bin/bash

EMERGE_OPTS="-b -k -n"

if [ "0${IS_LEGACY_BUILDER}" -eq 1 ]; then
    TEMPLATE_SCRIPTS_DIR="$(readlink -f .)"
fi

prepareChroot() {
    CHROOT_DIR="$1"

    if [ ! -r "${CHROOT_DIR}/dev/zero" ]; then
        mkdir -p "${CHROOT_DIR}/dev"
        sudo mount --rbind /dev "${CHROOT_DIR}/dev"
    fi
    if [ "$(stat -f -c '%T' "${CHROOT_DIR}/dev/shm" 2>/dev/null)" != "tmpfs" ]; then
        mkdir -p "${CHROOT_DIR}/dev/shm"
        sudo mount -t tmpfs shm "${CHROOT_DIR}/dev/shm"
        sudo chmod 1777 "${CHROOT_DIR}/dev/shm"
    fi
    if [ ! -r "${CHROOT_DIR}/proc/cpuinfo" ]; then
        mkdir -p "${CHROOT_DIR}/proc"
        sudo mount -t proc proc "${CHROOT_DIR}/proc"
    fi
    if [ ! -d "${CHROOT_DIR}/sys/dev" ]; then\
        mkdir -p "${CHROOT_DIR}/sys"
        sudo mount --bind /sys "${CHROOT_DIR}/sys"
    fi
    cp /etc/resolv.conf "${CHROOT_DIR}/etc/resolv.conf"
}

chrootCmd() {
    CHROOT_DIR="$1"
    shift
    CMD="$*"

    /usr/sbin/chroot "${CHROOT_DIR}" env -i /bin/bash -l -c "env-update"
    /usr/sbin/chroot "${CHROOT_DIR}" env -i /bin/bash -l -c "source /etc/profile && $CMD"
}

updateChroot() {
    CHROOT_DIR="$1"
    chrootCmd "${CHROOT_DIR}" "emerge ${EMERGE_OPTS} --update --deep --newuse --changed-use --with-bdeps=y @world"
}

updatePortage() {
    CHROOT_DIR="$1"
    chrootCmd "${INSTALL_DIR}" 'emerge -b -k --update portage'
}

mountCache() {
    CACHE_DIR="$1"
    CHROOT_DIR="$2"

    mkdir -p "${CACHE_DIR}/distfiles"
    mkdir -p "${CACHE_DIR}/binpkgs"

    mount

    umount "${CHROOT_DIR}/var/cache/distfiles" || true
    umount "${CHROOT_DIR}/var/cache/binpkgs" || true

    mount --bind "${CACHE_DIR}/distfiles" "${CHROOT_DIR}/var/cache/distfiles"
    mount --bind "${CACHE_DIR}/binpkgs" "${CHROOT_DIR}/var/cache/binpkgs"

    chrootCmd "${CHROOT_DIR}" 'chmod 755 /var/cache/binpkgs'
    chrootCmd "${CHROOT_DIR}" 'chmod 755 /var/cache/distfiles'
    chrootCmd "${CHROOT_DIR}" 'chown -R portage:portage /var/cache/binpkgs'
    chrootCmd "${CHROOT_DIR}" 'chown -R portage:portage /var/cache/distfiles'
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
    FILE="$(getFile "${TEMPLATE_CONTENT_DIR}" "$PREFIX" ".list" "${FLAVOR}")"
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

    getFile "${TEMPLATE_CONTENT_DIR}/package.$FLAGS/" "" "" "${FLAVOR}"
}

getQubesFlags() {
    FLAVOR="${1:-gnome}"
    FLAGS="$2"

    getFile "${TEMPLATE_CONTENT_DIR}/package.$FLAGS/" "" "-qubes" "${FLAVOR}"
}

setupBaseFlags() {
    CHROOT_DIR="$1"
    FLAVOR="${2:-gnome}"
    for flag in use mask accept_keywords
    do
        if [ -e "$(getBaseFlags "$FLAVOR" "$flag")" ]; then
            mkdir -p "${CHROOT_DIR}/etc/portage/package.$flag"
            cp "$(getBaseFlags "$FLAVOR" "$flag")" "${CHROOT_DIR}/etc/portage/package.$flag/standard"
        fi
    done
}

setupQubesFlags() {
    CHROOT_DIR="$1"
    FLAVOR="${2:-gnome}"
    for flag in use mask accept_keywords
    do
        if [ -e "$(getQubesFlags "$FLAVOR" "$flag")" ]; then
            mkdir -p "${CHROOT_DIR}/etc/portage/package.$flag"
            cp "$(getQubesFlags "$FLAVOR" "$flag")" "${CHROOT_DIR}/etc/portage/package.$flag/qubes"
        fi
    done
}

setupQubesOverlay() {
    CHROOT_DIR="$1"
    RELEASE="$2"
    rm -rf "${CHROOT_DIR}/var/db/repos/qubes"
    mkdir -p "${CHROOT_DIR}/var/db/repos/qubes"
    cat > "${CHROOT_DIR}/etc/portage/repos.conf/qubes.conf" <<EOF
[qubes]
location = /var/db/repos/qubes
sync-uri = https://github.com/fepitre/qubes-gentoo.git
sync-type = git
sync-git-verify-commit-signature = true
sync-openpgp-key-path = /usr/share/openpgp-keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc
sync-openpgp-key-refresh = false
auto-sync = yes
EOF
    if [ -n "$RELEASE" ] && [[ $RELEASE =~ ^[1-9]+\.[0-9]+$ ]]; then
        echo "sync-git-clone-extra-opts = --branch release$RELEASE" >> "${CHROOT_DIR}/etc/portage/repos.conf/qubes.conf"
    fi

    # Add @fepitre's key
    cp "${TEMPLATE_CONTENT_DIR}/../keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc" "${CHROOT_DIR}/usr/share/openpgp-keys/9FA64B92F95E706BF28E2CA6484010B5CDC576E2.asc"

    # Add Qubes overlay
    chrootCmd "${CHROOT_DIR}" "emaint sync -r qubes"
}

installBasePackages() {
    CHROOT_DIR="$1"
    FLAVOR="${2:-gnome}"

    PACKAGES="$(getBasePackagesList "$FLAVOR")"
    if [ -n "${PACKAGES}" ]; then
        echo "  --> Installing Gentoo packages..."
        echo "    --> Selected packages: ${PACKAGES}"
        chrootCmd "${CHROOT_DIR}" "emerge ${EMERGE_OPTS} ${PACKAGES}"
    fi
}

installQubesPackages() {
    CHROOT_DIR="$1"
    FLAVOR="${2:-gnome}"

    PACKAGES="$(getQubesPackagesList "$FLAVOR")"
    if [ -n "${PACKAGES}" ]; then
        echo "  --> Installing Qubes packages..."
        echo "    --> Selected packages: ${PACKAGES}"
        chrootCmd "${CHROOT_DIR}" "emerge ${EMERGE_OPTS} ${PACKAGES}"
    fi
}

setPortageProfile() {
    CHROOT_DIR="$1"
    FLAVOR="${2:-gnome}"
    if [ "$FLAVOR" == "xfce" ] || [ "$FLAVOR" == "gnome" ]; then
        # Select desktop/gnome/systemd profile
        chrootCmd "${CHROOT_DIR}" "eselect profile set default/linux/amd64/17.1/desktop/gnome/systemd"
    else
        # Select default systemd profile
        chrootCmd "${CHROOT_DIR}" "eselect profile set default/linux/amd64/17.1/systemd"
    fi
}
