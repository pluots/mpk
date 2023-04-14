# This makefile will build (via Cargo)

MAKEFLAGS=--warn-undefined-variables
VERSION=0.2.1
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

COMPDIR_PFX=/usr/share
COMPDIR_BASH=${COMPDIR_PFX}/bash-completion/completions
COMPDIR_FISH=${COMPDIR_PFX}/fish/vendor_completions.d
COMPDIR_ZSH=${COMPDIR_PFX}/zsh/vendor-completions

# Install from a prebuilt release, rather than building
USE_RELEASED_INSTALL=0

ifeq ($(USE_RELEASED_INSTALL),1)
BINSOURCE= .
MANSOURCE = doc
COMPLETESOURCE = completion
else
builddir=$(shell find target -name mpk-stamp -print0 | xargs -0 ls -t | head -n1 | xargs dirname)
BINSOURCE = target/release
MANSOURCE = $(builddir)
COMPLETESOURCE = $(builddir)
endif


all: mpk

mpk:
ifndef CARGO
	$(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info building...)
	cargo build --release


install: mpk
ifeq ($(OS),Windows_NT)
	$(error install does not yet work on Windows)
	exit 1
endif
	
	$(info installing binary, manpages, and shell completion scripts)
	$(info using prefix ${PREFIX})

	install -d ${BINDEST}
	install -d ${MANDEST}
	
	$(info copying binary: ${BINSOURCE} -> ${BINDEST})
	install ${BINSOURCE}/mpk ${BINDEST}/mpk
	
	$(info copying manpage: ${MANSOURCE} -> ${MANDEST})
	install -m 644 ${MANSOURCE}/mpk.1 ${MANDEST}/mpk.1

ifeq ($(INSTALL_COMPLETIONS),true)
	@INSTALLEDAC=0; \
	if [ -d "${COMPDIR_BASH}" ]; then \
		echo 'copying bash completion: "${COMPLETESOURCE}" -> "${COMPDIR_BASH}"'; \
		install "${COMPLETESOURCE}/mpk.bash" "${COMPDIR_BASH}/mpk"; \
		INSTALLEDAC=1; \
	fi; \
	if [ -d "${COMPDIR_FISH}" ]; then \
		echo 'copying fish completion: "${COMPLETESOURCE}" -> "${COMPDIR_FISH}"'; \
		install "${COMPLETESOURCE}/mpk.fish" "${COMPDIR_FISH}/mpk.fish"; \
		INSTALLEDAC=1; \
	fi; \
	if [ -d "${COMPDIR_ZSH}" ]; then \
		echo 'copying zsh completion: "${COMPLETESOURCE}" -> "${COMPDIR_ZSH}"'; \
		install "${COMPLETESOURCE}/_mpk" "${COMPDIR_ZSH}/_mpk"; \
		INSTALLEDAC=1; \
	fi; \
	if [ "$${INSTALLEDAC}" = "0" ]; then \
		echo did not find any directories to install autocompletion scripts; \
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
	rm -f ${BINDEST}/mpk
	rm -f ${MANDEST}/mpk.1
	rm -f ${COMPDIR_BASH}/mpk
	rm -f ${COMPDIR_FISH}/mpk.fish
	rm -f ${COMPDIR_ZSH}/_mpk
