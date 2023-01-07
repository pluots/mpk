VERSION=0.1.0

PREFIX=/usr/local
INSTALL=install
MANDIR=${PREFIX}/share/man
DESTDIR=${PREFIX}/bin
MAN=msgpack.1


CARGO := $(shell command -v cargo 2> /dev/null)

all: msgpack

msgpack:
ifndef CARGO
    $(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info building...)
	cargo build --release

install:
	$(INSTALL) -d $(DESTDIR)
	$(INSTALL) -d $(MANDIR)/man1
	$(INSTALL) $(TREE_DEST) $(DESTDIR)/$(TREE_DEST); \
	$(INSTALL) -m 644 doc/$(MAN) $(MANDIR)/man1/$(MAN)

clean:
ifndef CARGO
    $(error "cargo is not available, visit rustup.rs or install with your system package manager")
endif
	$(info cleaning target directory)
	cargo clean
