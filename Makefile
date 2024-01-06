CC           := cc
AR           := ar
UNAME        := $(shell uname -s)

OBJDIR       := build
LIBRARY      := $(OBJDIR)/libqrdec.a

OPTIMIZATION :=
WARNINGS     := -Wno-unknown-warning-option -Wno-shift-op-parentheses -Wno-logical-not-parentheses
INCLUDES     := -I"src/"
DEFS         := -D_XOPEN_SOURCE=600

CFLAGS        = -std=c99 -fPIC $(WARNINGS) $(INCLUDES) $(DEFS) $(OPTIMIZATION)
LDFLAGS       =
ARFLAGS       = rcs

SOURCE_FILES  := bch15_5.c binarize.c isaac.c qrdec.c qrdectxt.c rs.c util.c
SOURCES       := $(addprefix src/,$(SOURCE_FILES))
OBJECTS       := $(addprefix $(OBJDIR)/,$(SOURCES:.c=.o))

EXAMPLE_SFILES   := image.c main.c
EXAMPLE_SOURCES  := $(addprefix example/,$(EXAMPLE_SFILES))
EXAMPLE_OBJECTS  := $(addprefix $(OBJDIR)/,$(EXAMPLE_SOURCES:.c=.o))
EXAMPLE_TARGET   := $(OBJDIR)/qrdec-example
EXAMPLE_INCLUDES := $(shell pkg-config --cflags libpng)

EXAMPLE_CFLAGS    = $(CFLAGS) $(EXAMPLE_INCLUDES) -fPIE -fsanitize=address -fno-omit-frame-pointer
EXAMPLE_LDFLAGS   = $(LDFLAGS) $(shell pkg-config --libs libpng) -liconv -fPIE -fsanitize=address

ifndef VERBOSE
.SILENT:
endif

.PHONY: all
all: debug

.PHONY: production
production: DEFS += -DNDEBUG
production: OPTIMIZATION += -Os -flto -DNDEBUG
production: LDFLAGS += -flto
production: $(LIBRARY)

.PHONY: debug
debug: CFLAGS += -g -O0 -fsanitize=address -fno-omit-frame-pointer
debug: LDFLAGS += -g -fsanitize=address
debug: $(LIBRARY)

.PHONY: example
example: CFLAGS := $(EXAMPLE_CFLAGS)
example: $(EXAMPLE_TARGET)

.PHONY: clean
clean:
	@printf "\e[1;31m   RM\e[m $(OBJDIR)\n"
	rm -rf $(OBJDIR)

$(EXAMPLE_TARGET): $(LIBRARY) $(EXAMPLE_OBJECTS)
	@printf "\e[1;32m LINK\e[m $@\n"
	$(CC) $^ $(EXAMPLE_LDFLAGS) -o $@

$(LIBRARY): $(OBJECTS)
	@printf "\e[1;32m   AR\e[m $@\n"
	$(AR) $(ARFLAGS) $@ $^

$(OBJECTS): | $(OBJDIR)/src/
$(EXAMPLE_OBJECTS): | $(OBJDIR)/example/

$(OBJDIR)/%.d:
	@true

$(OBJDIR)/%.o: %.c
	@printf "\e[1;34m   CC\e[m $<\n"
	$(CC) $(CFLAGS) -MMD -MF $(@:.o=.d) -c $< -o $@

$(OBJDIR):
	@printf "\e[1;33mMKDIR\e[m $@\n"
	mkdir -p $@

$(OBJDIR)/%/: | $(OBJDIR)
	@printf "\e[1;33mMKDIR\e[m $@\n"
	mkdir -p $@

-include $(OBJECTS:.o=.d) $(EXAMPLE_OBJECTS:.o=.d)
