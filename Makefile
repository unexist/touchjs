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
	src/userdata.c

SRC_TJS_CONTROLS= \
	src/controls/super.c \
	src/controls/scrubber.c \
	src/controls/label.c \
	src/controls/button.c \
	src/controls/slider.c

SRC_TJS_WINDOWS= \
	src/windows/win.m \
	src/windows/wm.m

SRC_LIB_DUKTAPE= \
	src/libs/duktape/duktape.c

SOURCES=$(SRC_TOUCHJS) \
	$(SRC_TJS_CONTROLS) \
	$(SRC_TJS_WINDOWS) \
	$(SRC_LIB_DUKTAPE)

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
