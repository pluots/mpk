#!/bin/sh

# Make a release archive

set -e -u -x
# set -o pipefail

staging="$STAGING_DIR"
assetdir="$CARGO_ASSETDIR"
builddir="$CARGO_BUILDDIR"
version="$RELEASE_VERSION"

echo staging: "$staging"
echo assets: "$assetdir"
echo build: "$builddir"
echo version: "$version"

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=linux;;
    Darwin*)    machine=mac;;
    CYGWIN*)    machine=cygwin;;
    MINGW*)     machine=mingw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

mkdir -p "${staging}/completion"
mkdir -p "${staging}/doc"

# Remove the "unreleased" section from our changelog
perl -0777 -pe "s/(<\!-- next-header -->.*## \[Unreleased\].*?\n)(?=## |<\!--)//gms" CHANGELOG.md > CHANGELOG.md.dist
sh dist/create_install_makefile.sh

# Build RELNOTES.md, which we will use for our Github release (not shipped in zip)
# Select the release notes from our latest version only
perl -0777 -ne "print /(## \[$version\].*?\n)(?=\n*^(?:## |<\!--))/gms" CHANGELOG.md > RELNOTES.md
# Select the diff URL for this version only
perl -0777 -ne "print /\n\[$version\]:.*?\n/gms" CHANGELOG.md >> RELNOTES.md

echo "Release notes:"
cat RELNOTES.md

# Create Makefile.dist for shipping with the package

cp README.md "${staging}/"
cp LICENSE "${staging}/"
cp Makefile.dist "${staging}/Makefile"
cp CHANGELOG.md.dist "${staging}/doc/CHANGELOG.md"
cp dist/INSTALLING "${staging}/"

# Copy manpages
cp "${assetdir}/mpk.1" "${staging}/doc"

completion_scripts="_mpk _mpk.ps1 mpk.bash mpk.elv mpk.fish"
for script in $completion_scripts; do
    cp "${assetdir}/${script}" "${staging}/completion"
done

if [ "$machine" = "cygwin" ]; then
    cp "${builddir}/mpk.exe" "${staging}/"
    sha256sum staging/mpk.exe | perl -pe "s/${staging}\///" >> "${staging}/sha256sum"
    7z a "${staging}.zip" "$staging"
    echo "ASSET=${staging}.zip" >> "$GITHUB_ENV"
else
    cp "${builddir}/mpk" "$staging/"
    shasum -a 256 staging/mpk | perl -pe "s/${staging}\///" >> "${staging}/sha256sum"
    tar czf "${staging}.tar.gz" "$staging"
    echo "ASSET=${staging}.tar.gz" >> "$GITHUB_ENV"
fi
