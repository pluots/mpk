#!/bin/bash

# Create a .deb package
# This script originates from https://github.com/sharkdp/fd

set -e -u -x -o pipefail


project_name=msgpack
project_maintainer="Trevor Gross"
project_homepage="https://github.com/pluots/msgpack-cli"
staging_dir="$STAGING_DIR"

copyright_years="2023 - "$(date "+%Y")
DPKG_STAGING="./debian-package"
DPKG_DIR="${DPKG_STAGING}/dpkg"
mkdir -p "${DPKG_DIR}"

dpkg_basename="$project_name"
# dpkg_conflicts=msgpack-musl

# case "$TARGET" in *-musl) dpkg_basename=${project_name}-musl
#     dpkg_conflicts=${project_name} ;;
# esac;

dpkg_version=${RELEASE_VERSION}

unset dpkg_arch
case "$TARGET" in
    aarch64-*-linux-*) dpkg_arch=arm64 ;;
    arm-*-linux-*hf) dpkg_arch=armhf ;;
    i686-*-linux-*) dpkg_arch=i686 ;;
    x86_64-*-linux-*) dpkg_arch=amd64 ;;
    *) dpkg_arch=notset ;;
esac;

DPKG_NAME="${dpkg_basename}_${dpkg_version}_${dpkg_arch}.deb"
# echo "DPKG_NAME=${DPKG_NAME}" >> $GITHUB_OUTPUT

# Binary
install -Dm755 "${staging_dir}/${project_name}" "${DPKG_DIR}/usr/bin/${project_name}"

# Man page
install -Dm644 "${staging_dir}/doc/${project_name}.1" "${DPKG_DIR}/usr/share/man/man1/${project_name}.1"
gzip -n --best "${DPKG_DIR}/usr/share/man/man1/${project_name}.1"

# Autocompletion files
install -Dm644 "${staging_dir}/completion/msgpack.bash" "${DPKG_DIR}/usr/share/bash-completion/completions/$project_name"
install -Dm644 "${staging_dir}/completion/msgpack.fish" "${DPKG_DIR}/usr/share/fish/vendor_completions.d/$project_name.fish"
install -Dm644 "${staging_dir}/completion/_msgpack" "${DPKG_DIR}/usr/share/zsh/vendor-completions/_$project_name"

# README and LICENSE
install -Dm644 "${staging_dir}/README.md" "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/README.md"
install -Dm644 "${staging_dir}/LICENSE" "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/LICENSE"
install -Dm644 "${staging_dir}/doc/CHANGELOG.md" "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/changelog"
gzip -n --best "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/changelog"

cat > "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/copyright" <<EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project_name}
Source: ${project_homepage}

Files: *
Copyright: ${copyright_years} ${project_maintainer}
License: Apache-2.0

License: Apache-2.0
    On Debian systems, the complete text of the Apache-2.0 can be found in the
    file /usr/share/common-licenses/Apache-2.0.
EOF

chmod 644 "${DPKG_DIR}/usr/share/doc/${dpkg_basename}/copyright"

# control file
mkdir -p "${DPKG_DIR}/DEBIAN"
cat > "${DPKG_DIR}/DEBIAN/control" <<EOF
Package: ${dpkg_basename}
Version: ${dpkg_version}
Section: utils
Priority: optional
Maintainer: ${project_maintainer}
Homepage: ${project_homepage}
Architecture: ${dpkg_arch}
Provides: ${project_name}
Description: A simple tool for converting between MessagePack and JSON formats
EOF
# Conflicts: ${dpkg_conflicts}

DPKG_PATH="${DPKG_STAGING}/${DPKG_NAME}"
echo "DPKG_PATH=${DPKG_PATH}" >> "$GITHUB_ENV"

# build dpkg
fakeroot dpkg-deb --build "${DPKG_DIR}" "${DPKG_PATH}"

echo "ASSET=${DPKG_PATH}" >> "$GITHUB_ENV"
