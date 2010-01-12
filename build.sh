#!/bin/bash

echo $PATH

if test "$(id -u)" -ne "0"
then
    echo "Super user required" >&2
    exit 1
fi

. $(dirname $0)/config

NAME=$1

if test -z "$NAME"
then
	NAME=$BUILDID
fi

TEMPDIR="$(mktemp -d -t $NAME.XXXXXXXX)" || exit 1

mailerror () {
echo BUILD FAILED at $NAME
echo "$LOG" |
mail -a 'From: hendry@webconverger.com' -s "failed" kai.hendry@gmail.com
exit 1
}

if test "$DEBUG"
then
	echo DEBUG MODE - $TEMPDIR needs to be manually deleted
else
	trap "cd $TEMPDIR/config-webc/webconverger; lh clean --purge; rm -vrf $TEMPDIR" 0 1 2 3 9 15
fi

chmod a+rx $TEMPDIR && cd $TEMPDIR

mount

if test "$(/sbin/losetup -a | wc -l)" -gt 0
then
	echo Unclean mounts!
	losetup -a
	exit
fi

echo Live Helper Version:
dpkg --status live-helper | egrep "^Version" | awk '{print $2}'

# Live helper configuration (Webconverger)
git clone git://git.debian.org/git/debian-live/config-webc.git

cd config-webc/webconverger

# info about the git repo
git rev-parse HEAD

lh config

lh build || mailerror
ls -lh
for f in binary.*; do mv "$f" "${OUTPUT}/${NAME}-usb.${f##*.}"; done
rm -f $OUTPUT/.htaccess
echo "Redirect /latest.img /${NAME}-usb.img" > $OUTPUT/.htaccess

if test -n "$ISO"
then
	echo Building ISO
	lh clean noautoconfig --binary
	lh config noautoconfig --source true -b iso --bootappend-live "quiet homepage=http://portal.webconverger.com/ nonetworking nosudo splash video=vesa:ywrap,mtrr vga=788 nopersistent"

	lh binary || mailerror

	for f in binary.*; do mv "$f" "$OUTPUT/${NAME}-iso.${f##*.}"; done
	echo "Redirect /latest.iso /${NAME}-iso.iso" >> $OUTPUT/.htaccess
fi

if test -n "$SOURCE"
then
	lh source
	mv source.list "$OUTPUT/$NAME.source.list"
	mv source.tar.gz "$OUTPUT/$NAME.tar.gz"
fi

chown -R www-data:www-data $OUTPUT
