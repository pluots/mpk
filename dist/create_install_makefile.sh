#!/bin/sh
# Generate a makefile suitable for prebuilt binaries

set -e -u -x -o pipefail

# Remove all targets except install & uninstall
perl -0777 -pe 's/^(?!install|uninstall)\w+:.*?(?=^\w+:|\Z)//gms' Makefile > Makefile.dist

# Strip target prerequisites
perl -0777 -i -pe 's/^((?:install|uninstall):)(.+)$/$1/gm' Makefile.dist

# Remove BUILDDIR, update man & complete locations
perl -0777 -i -pe 's/^\s+builddir=.*$//gm' Makefile.dist
perl -0777 -i -pe 's/^(\s+BUILT_MANDIR=).*$/$1\/doc/gm' Makefile.dist
perl -0777 -i -pe 's/^(\s+USE_RELEASED_INSTALL=).*$/$1 1/gm' Makefile.dist
