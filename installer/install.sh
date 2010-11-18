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
    PREFIX="$HOME/ranguba"
fi
if test -z "$HTTPD_PREFIX"; then
    HTTPD_PREFIX="/usr/local"
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
    if test -z $(getent passwd | grep ${RANGUBA_USERNAME}); then
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

function install_passenger() {
    if test -n "$APXS2_PATH" -a -n "$APR_CONFIG_PATH"; then
	ruby -S passenger-install-apache2-module -a \
	    --apxs2-path "$APXS2_PATH" \
	    --apr-config-path "$APR_CONFIG_PATH" 1>&$log 2>&1 || abort
    elif test -n "$APXS2_PATH" -a -z "$APR_CONFIG_PATH"; then
	ruby -S passenger-install-apache2-module -a \
	    --apxs2-path "$APXS2_PATH" 1>&$log 2>&1 || abort
    elif test -z "$APXS2_PATH" -a -n "$APR_CONFIG_PATH"; then
	ruby -S passenger-install-apache2-module -a \
	    --apr-config-path "$APR_CONFIG_PATH" 1>&$log 2>&1 || abort
    else
	ruby -S passenger-install-apache2-module -a 1>&$log 2>&1 || abort
    fi
    if [ ! -f ranguba.conf ]; then
        ruby -S passenger-install-apache2-module --snippet > ranguba.conf
	cat > passenger.conf <<EOF
RailsBaseURI /ranguba
<Directory ${PREFIX}/srv/www/ranguba>
  Options -MultiViews
</Directory>
EOF
    fi

    if test -n "$APXS2_PATH"; then
	sysconfdir=$(${APXS2_PATH} -q SYSCONFDIR)
	cp ranguba.conf "$sysconfdir/extra/"
	echo include conf/extra/ranguba.conf >> "$sysconfdir/httpd.conf"
    else
	APXS2_PATH=$(ruby -rphusion_passenger -e 'print PhusionPassenger::PlatformInfo.apxs2')
	if test -n $APXS2_PATH; then
	    sysconfdir=$(${APXS2_PATH} -q SYSCONFDIR)
	    cp ranguba.conf "$sysconfdir/extra/"
	    echo include conf/extra/ranguba.conf >> "$sysconfdir/httpd.conf"
	else
	    if test $HTTPD_PREFIX; then
		cp ranguba.conf $HTTPD_PREFIX/conf/extra/
		echo include conf/extra/ranguba.conf >> $HTTPD_PREFIX/conf/httpd.conf
	    else
		abort <<EOF
Please run below commands.
$ cp ranguba.conf <your httpd.conf directory>
$ echo include <path/to/ranguba.conf> >> <your httpd.conf>
EOF
	    fi
	fi
    fi
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
    bash ./install_from_source_packages.sh

export PATH="$PREFIX/bin:$PATH"
install_passenger

test $fd && echo "Finished: $(LC_ALL=C date)" 1>&$log
exec 3>&-

# Local Variables:
# tab-width: 8
# indent-tabs-mode: t
# End:

