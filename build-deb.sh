#!/bin/sh
# Builds dist/hal2027_<version>_armel.deb from this tree (any Linux with dpkg-deb).
set -e
cd "$(dirname "$0")"
VERSION=$(sed -n 's/^Version: //p' packaging/control)
P=$(mktemp -d)
chmod 755 $P
A=$P/opt/hal2027
D=$P/usr/share/doc/hal2027
mkdir -p $P/DEBIAN $A/espeak $P/usr/share/applications $D $P/usr/share/icons/hicolor/80x80/apps
cp packaging/control $P/DEBIAN/
cp src/main.py src/uslugi.json helper/hal2027-fetch $A/
cp -r src/qml $A/
cp espeak/espeak-ng $A/espeak/
cp -r espeak/espeak-ng-data $A/espeak/
chmod 755 $A/hal2027-fetch $A/espeak/espeak-ng
cp packaging/hal2027.desktop $P/usr/share/applications/
cp packaging/copyright $D/
cp -r packaging/doc/* $D/
cp src/hal2027-80.png $P/usr/share/icons/hicolor/80x80/apps/
(cd $P && find opt usr -type f -print0 | sort -z | xargs -0 md5sum > DEBIAN/md5sums)
mkdir -p dist
dpkg-deb -Zgzip --root-owner-group -b $P dist/hal2027_${VERSION}_armel.deb
rm -rf $P
