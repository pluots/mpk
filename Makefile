VERSION=0.1.0

DESTDIR=
PREFIX=/usr/local
AUTOPFX=/usr/share

MANDIR=${DESTDIR}/${PREFIX}/share/man
BINDIR=${DESTDIR}/${PREFIX}/bin
MANFILE=msgpack.1

BASHACDIR="${AUTOPFX}/bash-completion/completions"
FISHACDIR="${AUTOPFX}/fish/vendor_completions.d"
ZSHACDIR="${AUTOPFX}/zsh/vendor-completions/

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
	install -d ${MANDIR}/man1
	install target/release/msgpack ${DESTDIR}/msgpack; \
	install -m 644 ${BUILDDIR}/${MAN} ${MANDIR}/man1/${MAN}

	INSTALLEDAC=0


	if [ -d "${BASHACDIR}" ]; then \
		install ${BUILDDIR}/msgpack.bash ${BASHACDIR}/msgpack.bash; \
		$(info installed bash autocomplete); \
		INSTALLEDAC=1
	fi

	if [ -d "${FISHACDIR}" ]; then \
		install ${BUILDDIR}/msgpack.fish ${FISHACDIR}/msgpack.fish; \
		$(info installed fish autocomplete); \
	fi

	if [ -d "${ZSHACDIR}" ]; then \
		install ${BUILDDIR}/_msgpack ${ZSHACDIR}; \
		$(info installed zsh autocomplete); \
	fi


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
