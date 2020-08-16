SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
srcdir = Sources

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
SOURCES = $(wildcard $(srcdir)/**/*.swift)

.DEFAULT_GOAL = all

.PHONY: all
all: chat-bot-sdk

chat-bot-sdk: $(SOURCES)
	@swift build \
		-c release \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

.PHONY: install
install: chat-bot-sdk
	@install -d "$(bindir)"
	@install "$(BUILDDIR)/release/chat-bot-sdk" "$(bindir)"

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/chat-bot-sdk"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)
