#!/bin/sh
# Generate a makefile suitable for prebuilt binaries

# Remove all targets except install & uninstall
perl -0777 -pe 's/^(?!install|uninstall)\w+:.*?(?=^\w+:|\Z)//gms' Makefile > Makefile.tmp

# Strip target prerequisites
perl -0777 -i -pe 's/^((?:install|uninstall):)(.+)$/$1/gm' Makefile.tmp

# Remove BUILDDIR, update man & complete locations
perl -0777 -i -pe 's/^\s+BUILDDIR=.*$//gm' Makefile.tmp
perl -0777 -i -pe 's/^(\s+BUILT_MANDIR=).*$/$1\/doc/gm' Makefile.tmp
perl -0777 -i -pe 's/^(\s+BUILT_COMPLETEDIR=).*$/$1\/completion/gm' Makefile.tmp
