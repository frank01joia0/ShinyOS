.RECIPEPREFIX := >

PROG := shiny-efiboot
SRCS := shiny-efiboot.c

TARGET_CC ?= $(shell command -v musl-gcc >/dev/null 2>&1 && echo musl-gcc || echo gcc)
TARGET_CFLAGS ?= -static -Os -s -Wall -Wextra

DESTDIR ?= ../../build/userland
BINDIR := $(DESTDIR)/usr/sbin

.PHONY: all install clean

all: $(PROG)

$(PROG): $(SRCS)
>$(TARGET_CC) $(TARGET_CFLAGS) -o $(PROG) $(SRCS)

install: $(PROG)
>mkdir -p "$(BINDIR)"
>cp "$(PROG)" "$(BINDIR)/$(PROG)"
>chmod 755 "$(BINDIR)/$(PROG)"

clean:
>rm -f "$(PROG)"
