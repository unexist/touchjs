CC=clang
FRAMEWORKS=-framework Cocoa -framework DFRFoundation -F /System/Library/PrivateFrameworks
CFLAGS=-mmacosx-version-min=10.12 -x objective-c
INCLUDES=-Isrc/duktape
LDFLAGS=-fobjc-link-runtime -lm $(FRAMEWORKS)
SOURCES=src/touchjs.m src/duktape/duktape.c
OBJECTS=src/touchjs.o src/duktape/duktape.o
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
	$(CC) -c $(CFLAGS) $< -o $@

kill:
	@pkill $(OUT) ; true

clean:
	@rm -f *~ $(OUT) *.o
	@rm -rf "$(BUNDLE)"
