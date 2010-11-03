#!/bin/bash

set -e

BASE_DIR=$(dirname "$0")
SOURCE="$BASE_DIR/sources"

nocheck=no
noinst=no
showlist=no
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

if test -z "$1"; then
    PREFIX="$HOME/ranguba"
else
    PREFIX="$1"
    shift
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

function download() {
    for url do
	test -f "${SOURCE}/${url##*/}" || missing=("${missing[@]}" "$url")
    done
}

function inst() {
    local base="${1##*/}"
    download "$1"
    shift
    installs=("${installs[@]}" "$SEPARATOR" "$base" "$@")
}

function do_install1() {
    local base patched

    echo "Install: [$(date +%Y/%m/%d-%H:%M:%S)] $1" 1>&$log

    case "$1" in
      (*.tar.bz2)
	echo -n "Extracting $1..."
	mkdir -p build
	tar xpjf "${SOURCE}/$1" -C build 1>&$log 2>&1 || abort
	echo done
	base=${1%.tar.bz2}
	;;
      (*.tar.gz)
	echo -n "Extracting $1..."
	mkdir -p build
	tar xpzf "${SOURCE}/$1" -C build 1>&$log 2>&1 || abort
	echo done
	base=${1%.tar.gz}
	;;
      (*.gem)
	echo -n "Installing $1..."
	ruby -C "${SOURCE}" -S gem install --no-ri --no-rdoc --local "$1" 1>&$log 2>&1 || abort
	echo done
	return
	;;
    esac

    while shift; do
	case "$1" in
	  (--patch=*)
	    echo -n "Applying patch ${1#*=} to $base..."
	    patch -d "build/$base" -p1 < "${SOURCE}/${1#*=}" 1>&$log 2>&1 || abort
	    patched=yes
	    echo done
	    ;;
	  (*)
	    break
	    ;;
	esac
    done

    (cd "build/$base"
    if test \( -f configure.in -a ! configure -nt configure.in \) \
	 -o \( -f configure.ac -a ! configure -nt configure.ac \); then
	exec autoconf
    fi) 1>&$log 2>&1

    if test -f "build/$base/configure"; then
	echo -n "Configuring $base..."
	(
	    cd "build/$base"
	    exec ./configure --enable-shared --prefix="$PREFIX" "$@"
	) 1>&$log 2>&1 || abort
	echo done
    fi

    echo -n "Building $base..."
    if test -f "build/$base/Makefile"; then
	test "$patched" = yes && make -C "build/$base" prereq 1>&$log 2>&1 || true
	make -C "build/$base" 1>&$log 2>&1 || abort
    elif test -f "build/$base/Rakefile"; then
	ruby -C "build/$base" -S rake 1>&$log 2>&1 || abort
    fi
    echo done

    echo -n "Installing $base..."
    if test -f "build/$base/GNUmakefile" -o -f "build/$base/Makefile"; then
	make -C "build/$base" prefix="$PREFIX" install 1>&$log 2>&1 || abort
    elif test -f "build/$base/Rakefile"; then
	ruby -C "build/$base" -S rake install 1>&$log 2>&1 || abort
    fi
    echo done

    rm -fr "build/$base" > /dev/null 2>&1 || :
    rmdir build >/dev/null 2>&1 || :
}

function download_all() {
    if test ${#missing[@]} -gt 0; then
	wget -N -P "${SOURCE}" "${missing[@]}" || abort
    fi
}

function install_all() {
    local args arg
    until test ${#installs[@]} = 0; do
	args=()
	until test ${#installs[@]} = 0 || {
		arg="${installs}" installs=("${installs[@]:1}")
		test "$arg" = "$SEPARATOR"
	    } do
	    args=("${args[@]}" "${arg}")
	done
	test ${#args[@]} -gt 0 && do_install1 "${args[@]}"
    done
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

if ! test -d "${SOURCE}"; then
    mkdir -p sources
    SOURCE=sources
fi

if test "$nocheck" != yes; then
    missing=()
    for pkg in "${packages[@]}"; do
	if ! msg=$(rpm -q "$pkg" 2>&1); then
	    missing=("${missing[@]}" "$pkg")
	    echo "$msg"
	fi
    done
    if test ${#missing[@]} -gt 0; then
	abort "Please install missing packages first: 'yum install -y ${missing[@]}'"
    fi
fi

export PATH="$PREFIX/bin:$PATH"
export LD_RUN_PATH="$PREFIX/lib:${LD_RUN_PATH-/usr/$lib}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH-/usr/$lib}"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH-/usr/lib/pkgconfig}"

missing=()

inst http://www.ring.gr.jp/archives/GNU/autoconf/autoconf-2.68.tar.bz2
inst http://www.ring.gr.jp/archives/GNU/gettext/gettext-0.18.1.1.tar.gz
inst http://www.ring.gr.jp/archives/X/gnome/sources/glib/2.24/glib-2.24.2.tar.bz2
inst http://www.ring.gr.jp/archives/X/gnome/sources/libgsf/1.14/libgsf-1.14.19.tar.bz2
inst ftp://xmlsoft.org/libxml2/libxml2-2.7.7.tar.gz
inst ftp://xmlsoft.org/libxml2/libxslt-1.1.26.tar.gz
inst http://www.ring.gr.jp/archives/X/gnome/sources/atk/1.29/atk-1.29.4.tar.bz2
inst http://fontconfig.org/release/fontconfig-2.8.0.tar.gz
inst http://downloads.sourceforge.net/project/freetype/freetype2/2.4.3/freetype-2.4.3.tar.bz2

inst http://cairographics.org/releases/pixman-0.18.4.tar.gz
inst http://cairographics.org/releases/cairo-1.8.10.tar.gz
inst http://www.ring.gr.jp/archives/X/gnome/sources/pango/1.28/pango-1.28.3.tar.bz2

inst http://www.ring.gr.jp/archives/X/gnome/sources/gtk+/2.20/gtk+-2.20.1.tar.bz2
inst http://www.ring.gr.jp/archives/X/gnome/sources/libglade/2.6/libglade-2.6.4.tar.bz2
inst http://poppler.freedesktop.org/poppler-0.14.4.tar.gz
inst http://poppler.freedesktop.org/poppler-data-0.4.3.tar.gz

inst http://downloads.sourceforge.net/project/wvware/wv/1.2.4/wv-1.2.4.tar.gz
inst http://www.ring.gr.jp/archives/X/gnome/sources/goffice/0.8/goffice-0.8.11.tar.bz2
inst http://www.ring.gr.jp/archives/X/gnome/sources/gnumeric/1.10/gnumeric-1.10.11.tar.gz
inst http://www.ring.gr.jp/archives/X/gnome/sources/gnumeric/1.10/gnumeric-1.10.11.tar.gz
inst http://dag.wieers.com/home-made/unoconv/unoconv-0.4.tar.bz2

inst http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p0.tar.bz2 \
     --disable-install-doc
inst http://rubygems.org/downloads/pkg-config-1.0.7.gem
inst http://downloads.sourceforge.net/project/ruby-gnome2/ruby-gnome2/ruby-gnome2-0.90.5/ruby-gtk2-0.90.5.tar.gz

inst http://rubygems.org/downloads/nokogiri-1.4.3.1.gem

# inst cutter-1.1.5.tar.gz
inst http://groonga.org/files/groonga/groonga-1.0.2.tar.gz
inst http://rubygems.org/downloads/rroonga-1.0.1.gem
inst http://rubygems.org/downloads/racknga-0.9.0.gem
inst http://rubyforge.org/frs/download.php/73144/chupatext-0.4.0.tar.gz
# inst http://rubygems.org/downloads/chuparuby-0.5.0.gem
inst http://rubygems.org/downloads/chupatext-0.4.0.gem
# inst ranguba-0.1.0.tar.gz

download http://rubygems.org/downloads/abstract-1.0.0.gem
download http://rubygems.org/downloads/actionmailer-3.0.1.gem
download http://rubygems.org/downloads/actionpack-3.0.1.gem
download http://rubygems.org/downloads/activemodel-3.0.1.gem
download http://rubygems.org/downloads/activerecord-3.0.1.gem
download http://rubygems.org/downloads/activeresource-3.0.1.gem
download http://rubygems.org/downloads/activesupport-3.0.1.gem
download http://rubygems.org/downloads/arel-1.0.1.gem
download http://rubygems.org/downloads/builder-2.1.2.gem
download http://rubygems.org/downloads/bundler-1.0.3.gem
download http://rubygems.org/downloads/erubis-2.6.6.gem
download http://rubygems.org/downloads/i18n-0.4.1.gem
download http://rubygems.org/downloads/mail-2.2.7.gem
download http://rubygems.org/downloads/mime-types-1.16.gem
download http://rubygems.org/downloads/polyglot-0.3.1.gem
download http://rubygems.org/downloads/rack-1.2.1.gem
download http://rubygems.org/downloads/rack-mount-0.6.13.gem
download http://rubygems.org/downloads/rack-test-0.5.6.gem
download http://rubygems.org/downloads/railties-3.0.1.gem
download http://rubygems.org/downloads/thor-0.14.3.gem
download http://rubygems.org/downloads/treetop-1.4.8.gem
download http://rubygems.org/downloads/tzinfo-0.3.23.gem
inst http://rubygems.org/downloads/rails-3.0.1.gem

if test "$showlist" = yes; then
    echo "Packages to be installed:"
    show=yes
    for inst in "${installs[@]}"; do
	if test "$inst" = "$SEPARATOR"; then
	    show=yes
	else
	    test "$show" = yes && echo "* $inst"
	    show=no
	fi
    done
    echo "Packages to be downloaded:"
    for url in "${missing[@]}"; do
	echo "* $url"
    done
else
    download_all
    test "$noinst" = yes || install_all
fi

test $fd && echo "Finished: $(LC_ALL=C date)" 1>&$log
exec 3>&-
