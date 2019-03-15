CC=clang
FRAMEWORKS=-framework AppKit \
	-framework IOKit \
	-framework Carbon \
	-framework Cocoa \
	-framework DFRFoundation \
	-framework Quartz \
	-F /System/Library/PrivateFrameworks

INCLUDES=-Isrc/duktape
CFLAGS=-mmacosx-version-min=10.12 -x objective-c
LDFLAGS=-fobjc-link-runtime -lm $(FRAMEWORKS)

SRC_TOUCHJS= \
	src/touchjs.m \
	src/command.m \
	src/global.c \
	src/userdata.c \
	src/controls/super.c \
	src/controls/scrubber.c \
	src/controls/label.c \
	src/controls/button.c \
	src/controls/slider.c

SRC_SILICA= \
	src/libs/silica/NSRunningApplication+Silica.m \
	src/libs/silica/NSScreen+Silica.m \
	src/libs/silica/SIAccessibilityElement.m \
	src/libs/silica/SIApplication.m \
	src/libs/silica/SISystemWideElement.m \
	src/libs/silica/SIUniversalAccessHelper.m \
	src/libs/silica/SIWindow.m

SRC_DUKTAPE= \
	src/libs/duktape/duktape.c

SOURCES=$(SRC_TOUCHJS) \
	$(SRC_SILICA) \
	$(SRC_DUKTAPE)

TEMP=$(SOURCES:.m=.o)
OBJECTS=$(TEMP:.c=.o)

OUT=touchjs
BUNDLE=touchjs.app

all: $(SOURCES) $(OUT)
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@cp "$(OUT)" "$(BUNDLE)/Contents/MacOS/"
	@cp Info.plist "$(BUNDLE)/Contents"

run: all kill
	@open "$(BUNDLE)"

$(OUT): $(OBJECTS)
	$(CC) $(INCLUDES) $(OBJECTS) $(LDFLAGS) -o $(OUT)

.m.o:
	$(CC) -c $(CFLAGS) $< -o $@

.c.o:
	$(CC) -c $(CFLAGS) -DDUK_USE_DEBUG -DDUK_USE_DEBUG_LEVEL=0 $< -o $@

kill:
	@pkill $(OUT) ; true

clean:
	@rm -f *~ $(OUT) $(OBJECTS)
	@rm -rf "$(BUNDLE)"
