CC=clang
FRAMEWORKS=-framework Cocoa -framework DFRFoundation -F /System/Library/PrivateFrameworks

INCLUDES=-Isrc/duktape
CFLAGS=-mmacosx-version-min=10.12 -x objective-c
LDFLAGS=-fobjc-link-runtime -lm $(FRAMEWORKS)

SOURCES= \
	src/touchjs.m \
	src/command.m \
	src/global.c \
	src/userdata.c \
	src/controls/super.c \
	src/controls/label.c \
	src/controls/button.c \
	src/controls/slider.c \
	src/duktape/duktape.c

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
