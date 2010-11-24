#!/bin/bash

set -e

BASE_DIR=$(dirname "$0")
SOURCE="$BASE_DIR/sources"

nocheck=no
noinst=no
showlist=no
install_ranguba_only=no
until test $# = 0; do
    case "$1" in
      (--download-only)
	nocheck=yes
	noinst=yes
	;;
      (--list)
	nocheck=yes
	noinst=yes
	showlist=yes
	;;
      (--check-only)
	noinst=yes
	;;
      (--install-ranguba-only)
	install_ranguba_only=yes
	;;
      (--user)
	shift
	RANGUBA_USERNAME="$1"
	;;
      (--prefix)
	shift
	PREFIX="$1"
	;;
      (--httpd-prefix)
	shift
	HTTPD_PREFIX="$1"
	;;
      (--apxs2-path)
	shift
	APXS2_PATH="$1"
	;;
      (--apr-config-path)
	shift
	APR_CONFIG_PATH="$1"
	;;
      (--document-root)
	shift
	DOCUMENT_ROOT="$1"
	;;
      (--)
	shift
	break
	;;
      (-*)
	echo "$0: unknown option $1" 1>&2
	exit 1
	;;
      (*)
	break
	;;
    esac
    shift
done

if test -z "$RANGUBA_USERNAME"; then
    RANGUBA_USERNAME="ranguba"
fi
if test -z "$PREFIX"; then
    PREFIX=$(echo ~${RANGUBA_USERNAME})
fi
if test -z "$HTTPD_PREFIX"; then
    HTTPD_PREFIX="/usr/local"
fi
if test -z "$DOCUMENT_ROOT"; then
    DOCUMENT_ROOT="$HTTPD_PREFIX/apache2/htdocs"
fi

SEPARATOR="
"

packages=(
    bison
    diffutils
    file
    gcc
    gcc-c++
    intltool
    make
    pkgconfig
    scrollkeeper
    wget
    which
    tar
    gzip
    cpio

    fontconfig-devel
    gamin-devel
    gettext-devel
    gtk+-devel
    gtk2-devel
    libgsf-devel
    libjpeg-devel
    libpng-devel
    libtiff-devel
    openssl-devel
    readline-devel
    bzip2-devel
    zlib-devel

    fonts-japanese

    curl-devel
)

function abort() {
    local status=$?
    if test $# = 0; then
	echo Failed
    else
	echo "$*"
    fi
    if test $status = 0; then
	status=1
    fi
    exit $status
}

function checkroot() {
    if test `id -u` -ne 0; then
	echo "This installer must be run with administrator privileges. Aborting"
	exit 1
    fi
}

function prepare_user() {
    if ! getent passwd | grep -q ${RANGUBA_USERNAME}; then
	/usr/sbin/useradd $RANGUBA_USERNAME
    fi
}

function check_rpm_packages() {
    local missing=()
    for pkg in "${packages[@]}"; do
	if ! msg=$(rpm -q "$pkg" 2>&1); then
	    missing=("${missing[@]}" "$pkg")
	    echo "$msg" 1>&$log
	fi
    done
    if test ${#missing[@]} -gt 0; then
	for pkg in "${missing[@]}"; do
	    yum install -y $pkg 1>&$log 2>&1
	done
    fi
}

function set_httpd_vars() {
    if test -x "$APXS2_PATH"; then
	HTTPD_CONF_DIR=$(${APXS2_PATH} -q SYSCONFDIR)
	APACHECTL_PATH=$(${APXS2_PATH} -q SBINDIR)/apachectl
    else
	APXS2_PATH=$(ruby -rphusion_passenger -rphusion_passenger/platform_info/apache -e 'print PhusionPassenger::PlatformInfo.apxs2')
	if test -x $APXS2_PATH; then
	    HTTPD_CONF_DIR=$(${APXS2_PATH} -q SYSCONFDIR)
	    APACHECTL_PATH=$(${APXS2_PATH} -q SBINDIR)/apachectl
	else
	    if test $HTTPD_PREFIX; then
		HTTPD_CONF_DIR=$HTTPD_PREFIX/conf/
		APACHECTL_PATH=$HTTPD_PREFIX/bin/apachectl
	    else
		echo <<EOF
Please run below commands.

  $ ruby -S passenger-install-apache2-module --snippet > ranguba.conf
  $ edit ranguba.conf
  $ cp ranguba.conf <your httpd.conf directory>
  $ echo include <path/to/ranguba.conf> >> <your httpd.conf>
EOF
	    fi
	fi
    fi
}

function append_ranguba_conf_to_httpd_conf() {
    set_httpd_vars
    if ! grep -q "ranguba.conf" "${HTTPD_CONF_DIR}/httpd.conf"; then
	echo "include ${PREFIX}/ranguba/ranguba.conf" >> "${HTTPD_CONF_DIR}/httpd.conf"
    fi
    if test ! -L "$DOCUMENT_ROOT/ranguba"; then
	ln -s "$PREFIX/ranguba/public" "$DOCUMENT_ROOT/ranguba"
    fi
    test -x $APACHECTL_PATH && $APACHECTL_PATH restart
}

case $ARCH in
  (x86_64*)
    lib=lib64
    ;;
  (*)
    lib=lib
    ;;
esac

if test "$noinst" = no; then
    exec 3> install.log
    log=3
else
    log=
fi
test $log && echo "Start: $(LC_ALL=C date)" 1>&$log
test $log && chmod 0666 install.log

checkroot
prepare_user

if ! test -d "${SOURCE}"; then
    sudo -u $RANGUBA_USERNAME mkdir -p sources
    SOURCE=sources
fi

if test "$nocheck" != yes; then
    check_rpm_packages
fi

sudo -H -u $RANGUBA_USERNAME \
    nocheck="$nocheck" \
    noinst="$noinst" \
    showlist="$showlist" \
    install_ranguba_only="$install_ranguba_only" \
    PREFIX="$PREFIX" \
    HTTPD_PREFIX="$HTTPD_PREFIX" \
    APXS2_PATH="$APXS2_PATH" \
    APR_CONFIG_PATH="$APR_CONFIG_PATH" \
    SOURCE="$SOURCE" \
    SEPARATOR="'$SEPARATOR'" \
    bash ./install_sources_and_gems.sh

if test "$noinst" = no; then
    append_ranguba_conf_to_httpd_conf
fi

test $fd && echo "Finished: $(LC_ALL=C date)" 1>&$log
exec 3>&-

# Local Variables:
# tab-width: 8
# indent-tabs-mode: t
# End:

