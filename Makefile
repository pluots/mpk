# This makefile will build (via Cargo)

VERSION=0.1.0

DESTDIR=
PREFIX=/usr/local
AUTOPFX=/usr/share

MANDIR=${DESTDIR}/${PREFIX}/share/man
BINDIR=${DESTDIR}/${PREFIX}/bin
MANFILE=msgpack.1

BASHACDIR="${AUTOPFX}/bash-completion/completions
FISHACDIR="${AUTOPFX}/fish/vendor_completions.d
ZSHACDIR="${AUTOPFX}/zsh/vendor-completions

CARGO := $(shell command -v cargo 2> /dev/null)

all: msgpack

msgpack:
ifndef CARGO
    $(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info building...)
	cargo build --release


install: msgpack
ifeq ($(OS),Windows_NT)
	$(error install does not yet work on Windows)
	exit 1
endif
	$(info installing binary, manpages, and shell complete)

	BUILDDIR="$(find target -name msgpack-stamp -print0 | xargs -0 ls -t | head -n1 | xargs dirname)"
	
	# We override these in our release script
	BUILT_MANDIR=${BUILDDIR}
	BUILT_COMPLETEDIR=${BUILDDIR}

	install -d ${MANDIR}/man1
	install target/release/msgpack ${DESTDIR}/msgpack; \
	install -m 644 ${BUILT_MANDIR}/${MANFILE} ${MANDIR}/man1/${MANFILE}

	INSTALLEDAC=0

	if [ -d "${BASHACDIR}" ]; then \
		install ${BUILDDIR}/msgpack.bash ${BASHACDIR}/msgpack.bash; \
		$(info installed bash autocomplete); \
		INSTALLEDAC=1
	fi

	if [ -d "${FISHACDIR}" ]; then \
		install ${BUILDDIR}/msgpack.fish ${FISHACDIR}/msgpack.fish; \
		$(info installed fish autocomplete); \
		INSTALLEDAC=1
	fi

	if [ -d "${ZSHACDIR}" ]; then \
		install ${BUILDDIR}/_msgpack ${ZSHACDIR}/_msgpack; \
		$(info installed zsh autocomplete); \
		INSTALLEDAC=1
	fi

ifeq (${INSTALLEDAC},0)
	$(info did not find any directorys to install autocompletion scripts)
endif


clean:
ifndef CARGO
    $(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info cleaning target directory)
	cargo clean


uninstall:
	$(info cleaning install directory)
	rm -f ${DESTDIR}/msgpack
	rm -f ${MANDIR}/man1/${MAN}
	rm -f ${BASHACDIR}/msgpack.bash
	rm -f ${FISHACDIR}/msgpack.fish
	rm -f ${ZSHACDIR}/_msgpack
