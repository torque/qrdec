CC           := cc
AR           := ar
UNAME        := $(shell uname -s)

OBJDIR       := build
LIBRARY      := $(OBJDIR)/libqrdec.a

OPTIMIZATION :=
WARNINGS     :=
INCLUDES     := -I"src/"
DEFS         := -D_XOPEN_SOURCE=600

CFLAGS        = -std=c99 -fPIC $(WARNINGS) $(INCLUDES) $(DEFS) $(OPTIMIZATION)
LDFLAGS       =
ARFLAGS       = rcs


SOURCE_FILES  := bch15_5.c binarize.c isaac.c qrdec.c qrdectxt.c rs.c util.c
SOURCES       := $(addprefix src/,$(SOURCE_FILES))
OBJECTS       := $(addprefix $(OBJDIR)/,$(SOURCES:.c=.o))

TEST_SFILES   := image.c reader.c
TEST_SOURCES  := $(addprefix src/,$(TEST_SFILES))
TEST_OBJECTS  := $(addprefix $(OBJDIR)/,$(TEST_SOURCES:.c=.o))
TEST_TARGET   := $(OBJDIR)/qrdec
TEST_INCLUDES := $(shell pkg-config --cflags libpng)

TEST_CFLAGS    = $(CFLAGS) $(TEST_INCLUDES) -fPIE
TEST_LDFLAGS   = $(LDFLAGS) $(shell pkg-config --libs libpng) -liconv $(LIBRARY) -fPIE

.PHONY: all debug test clean
ifndef VERBOSE
.SILENT:
endif

all: debug

production: DEFS += -DNDEBUG
production: OPTIMIZATION += -Os -flto -DNDEBUG
production: LDFLAGS += -flto
production: $(LIBRARY)

debug: CFLAGS += -g -O0 -fsanitize=address -fno-omit-frame-pointer
debug: LDFLAGS += -g -fsanitize=address
debug: $(LIBRARY)

test: $(TEST_TARGET)

$(TEST_TARGET): $(LIBRARY) $(TEST_OBJECTS)
	@printf "\e[1;32m LINK\e[m $@\n"
	$(CC) $^ $(TEST_LDFLAGS) -o $@

$(LIBRARY): $(OBJECTS)
	@printf "\e[1;32m   AR\e[m $@\n"
	$(AR) $(ARFLAGS) $@ $^

$(OBJECTS): $(DEPS) | $(OBJDIR)/src/

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

clean:
	@printf "\e[1;31m   RM\e[m $(OBJDIR)\n"
	rm -rf $(OBJDIR)

-include $(OBJECTS:.o=.d) $(TEST_OBJECTS:.o=.d)
