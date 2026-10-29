.RECIPEPREFIX := >

DESTDIR ?= ../../build/userland
SBINDIR := $(DESTDIR)/usr/sbin

.PHONY: all install clean

all:

install:
>mkdir -p "$(SBINDIR)"
>cp shiny-install "$(SBINDIR)/shiny-install"
>chmod 755 "$(SBINDIR)/shiny-install"

clean:
