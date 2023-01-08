# This makefile will build (via Cargo)

MAKEFLAGS=--warn-undefined-variables
VERSION=0.1.4
CARGO := $(shell command -v cargo 2> /dev/null)


# Install locations
DESTDIR=
PREFIX=/usr/local
MANDEST=${DESTDIR}${PREFIX}/share/man/man1
BINDEST=${DESTDIR}${PREFIX}/bin
INSTALL_COMPLETIONS=true

ifneq ($(DESTDIR),)
INSTALL_COMPLETIONS=false
endif

COMPDEST_PFX=/usr/share
COMPDEST_BASH=${COMPDEST_PFX}/bash-completion/completions
COMPDEST_FISH=${COMPDEST_PFX}/fish/vendor_completions.d
COMPDEST_ZSH=${COMPDEST_PFX}/zsh/vendor-completions

USE_RELEASED_INSTALL=0

ifeq ($(USE_RELEASED_INSTALL),1)
BINSOURCE= .
MANSOURCE = doc
COMPLETESOURCE = completion
else
builddir=$(shell find target -name msgpack-stamp -print0 | xargs -0 ls -t | head -n1 | xargs dirname)
BINSOURCE = target/release
MANSOURCE = $(builddir)
COMPLETESOURCE = $(builddir)
endif


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
	
	$(info installing binary, manpages, and shell completion scripts)
	$(info binary source: ${BINSOURCE})
	$(info manpage source: ${MANSOURCE})
	$(info completion source: ${COMPLETESOURCE})

	install -d ${BINDEST}
	install -d ${MANDEST}
	install ${BINSOURCE}/msgpack ${BINDEST}/msgpack
	install -m 644 ${MANSOURCE}/msgpack.1 ${MANDEST}/msgpack.1

ifeq ($(INSTALL_COMPLETIONS),true)
	INSTALLEDAC=0; \
	if [ -d "${COMPDEST_BASH}" ]; then \
		install "${COMPLETESOURCE}/msgpack.bash" "${COMPDEST_BASH}/msgpack"; \
		echo installed bash autocomplete; \
		INSTALLEDAC=1; \
	fi; \
	if [ -d "${COMPDEST_FISH}" ]; then \
		install "${COMPLETESOURCE}/msgpack.fish" "${COMPDEST_FISH}/msgpack.fish"; \
		echo installed fish autocomplete; \
		INSTALLEDAC=1; \
	fi; \
	if [ -d "${COMPDEST_ZSH}" ]; then \
		install "${COMPLETESOURCE}/_msgpack" "${COMPDEST_ZSH}/_msgpack"; \
		echo installed zsh autocomplete; \
		INSTALLEDAC=1; \
	fi; \
	if [ "$${INSTALLEDAC}" = "0" ]; then \
		echo did not find any directorys to install autocompletion scripts; \
	fi

else
	$(info skipping install of shell completion scripts)
endif

	$(info finished installation)

clean:
ifndef CARGO
    $(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info cleaning target directory)
	cargo clean


uninstall:
	$(info cleaning install directories)
	rm -f ${BINDEST}/msgpack
	rm -f ${MANDEST}/msgpack.1
	rm -f ${COMPDEST_BASH}/msgpack
	rm -f ${COMPDEST_FISH}/msgpack.fish
	rm -f ${COMPDEST_ZSH}/_msgpack
