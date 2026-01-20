##
# @package TouchJS
#
# @file Makefile
# @copyright 2019-present Christoph Kappel <christoph@unexist.dev>
# @version $Id: src/touchjs.m,v 79 2019/11/04 18:41:56 unexist $
#
# This program can be distributed under the terms of the GNU GPLv2.
# See the file COPYING for details.
##

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
DUKCFLAGS=-DDUK_USE_DEBUG -DDUK_USE_DEBUG_LEVEL=0

SRC_TOUCHJS= \
	src/touchjs.m \
	src/embed.m \
	src/touchbar.m

SRC_TJS_COMMON= \
	src/common/userdata.c \
	src/common/callback.c

SRC_TJS_OBJ_GLOBAL= \
	src/command.m \
	src/global.c

SRC_TJS_OBJ_WIDGETS= \
	src/widgets/widget.c \
	src/widgets/label.c \
	src/widgets/button.c \
	src/widgets/slider.c \
	src/widgets/scrubber.c

SRC_TJS_OBJ_WM= \
	src/wm/wm.m \
	src/wm/observer.m \
	src/wm/frame.m \
	src/wm/attr.m \
	src/wm/screen.m \
	src/wm/win.m

SRC_LIB_DUKTAPE= \
	src/libs/duktape/duktape.c

SOURCES=$(SRC_TOUCHJS) \
	$(SRC_TJS_COMMON) \
	$(SRC_TJS_OBJ_GLOBAL) \
	$(SRC_TJS_OBJ_WIDGETS) \
	$(SRC_TJS_OBJ_WM) \
	$(SRC_LIB_DUKTAPE)

TEMP=$(SOURCES:.m=.o)
OBJECTS=$(TEMP:.c=.o)

OUT=touchjs
BUNDLE=touchjs.app
BUILDDIR=build

all: $(SOURCES) $(OUT)
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@cp "$(OUT)" "$(BUNDLE)/Contents/MacOS/"
	@cp Info.plist "$(BUNDLE)/Contents"

$(OUT): $(OBJECTS)
	$(CC) $(INCLUDES) $(OBJECTS) $(LDFLAGS) -o $(OUT)

%/duktape.o: %/duktape.c
	$(CC) -c $(CFLAGS) $(DUKCFLAGS) $< -o $@

.m.o:
	$(CC) -c $(CFLAGS) $< -o $@

.c.o:
	$(CC) -c $(CFLAGS) $< -o $@

kill:
	@pkill $(OUT) ; true

clean:
	@rm -f *~ $(OUT) $(OBJECTS)
	@rm -rf "$(BUNDLE)"
