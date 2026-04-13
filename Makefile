.PHONY: fmt lint test install uninstall

SHELL_SCRIPTS := git-wt install.sh tests/test_git_wt.sh
PREFIX ?= $(HOME)/.local
DESTDIR ?=
BINDIR := $(DESTDIR)$(PREFIX)/bin
MANDIR := $(DESTDIR)$(PREFIX)/share/man/man1

fmt:
	shfmt -w $(SHELL_SCRIPTS)
	dprint fmt

lint:
	shellcheck $(SHELL_SCRIPTS)

test:
	./tests/test_git_wt.sh

install:
	mkdir -p "$(BINDIR)" "$(MANDIR)"
	install -m 0755 git-wt "$(BINDIR)/git-wt"
	install -m 0644 git-wt.1 "$(MANDIR)/git-wt.1"

uninstall:
	rm -f "$(BINDIR)/git-wt" "$(MANDIR)/git-wt.1"
