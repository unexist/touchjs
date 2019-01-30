/**
 * @package TouchJS
 *
 * @file Main functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "touchjs.h"
#import <Cocoa/Cocoa.h>

/* Constants */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

/* Forward declarations */
extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

/* Types */
typedef struct tjs_touch_t {
    int flags;

    TjsUserdata *userdata;

    /* Obj-c */
    NSTouchBarItemIdentifier identifier;
    NSView *view;
} TjsTouch;

/* Interfaces */
@interface NSTouchBarItem ()
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
@end

@interface NSTouchBar ()
/* macOS 10.14 and above */
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

/* macOS 10.13 and below */
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTouchBarDelegate>
@end

/* Globals */
NSTouchBar *_groupTouchBar;
NSMutableArray *_touchbarControls;

@implementation AppDelegate

/**
 * Handle group touchbar
 **/

- (NSTouchBar *)groupTouchBar {
    NSMutableArray *array;

    TJS_LOG_DEBUG("");

    /* Create if required */
    if (!_groupTouchBar) {
        NSTouchBar *groupTouchBar = [[NSTouchBar alloc] init];

        array = [NSMutableArray arrayWithCapacity: 1];

        groupTouchBar.delegate = self;
        groupTouchBar.defaultItemIdentifiers = array;

        _groupTouchBar = groupTouchBar;
    } else {
        //array = (NSMutableArray *)_groupTouchBar.defaultItemIdentifiers;

        //[array removeAllObjects];
        array = [NSMutableArray arrayWithCapacity: 1];
    }

    /* Collect identifiers */
    for (int i = 0; i < [_touchbarControls count]; i++) {
        TjsTouch *touch = [[_touchbarControls objectAtIndex: i] pointerValue];

        [array addObject: touch->identifier];
    }

    [array addObject: kQuit];

    _groupTouchBar.defaultItemIdentifiers = array;

    return _groupTouchBar;
}

/**
 * Set group touch bar
 **/

-(void)setGroupTouchBar:(NSTouchBar*)touchBar {
    _groupTouchBar = touchBar;
}

/**
 * Handle send event: button
 **/

- (void)button:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsTouch *touch = [[_touchbarControls objectAtIndex: idx] pointerValue];

    if (nil != touch && nil != touch->userdata) {
        TjsWidget *widget = (TjsWidget *)touch->userdata;

        TJS_LOG_DEBUG("flags=%d, idx=%d", widget->flags, idx);

        /* Get object and call callback */
        duk_get_global_string(_ctx, [touch->identifier UTF8String]);

        if (duk_is_object(_ctx, -1)) {
            tjs_super_callback_call(_ctx, TJS_SYM_CLICK_CB, 0);
        }
    }
}

/**
 * Handle send event: slider
 **/

- (void)slider:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsTouch *touch = [[_touchbarControls objectAtIndex: idx] pointerValue];

    if (nil != touch && nil != touch->userdata) {
        TjsWidget *widget = (TjsWidget *)touch->userdata;

        TJS_LOG_DEBUG("flags=%d, idx=%d", widget->flags, idx);

        /* Update value */
        NSSlider *slider = (NSSlider *)sender;

        double value = [slider doubleValue];

        if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            widget->value.asInt = value;
        }

        /* Get object and call callback */
        duk_get_global_string(_ctx, [touch->identifier UTF8String]);

        if (duk_is_object(_ctx, -1)) {
            duk_push_int(_ctx, value);
            tjs_super_callback_call(_ctx, TJS_SYM_SLIDE_CB, 1);
        }
    }
}

/**
 * Handle send event: present
 **/

- (void)present:(id)sender {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar: self.groupTouchBar
            systemTrayItemIdentifier: kGroupButton];
    } else {
        [NSTouchBar presentSystemModalFunctionBar: self.groupTouchBar
            systemTrayItemIdentifier: kGroupButton];
    }
}

/**
 * Make items for identifiers
 **/

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
       makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSCustomTouchBarItem *item = nil;

    /* Check identifiers */
    if ([identifier isEqualToString: kQuit]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier: kQuit];

        item.view = [NSButton buttonWithTitle:@"Quit"
            target:[NSApplication sharedApplication]
            action: @selector(terminate:)];
    } else {
        /* Create custom controls */
        for (int i = 0; i < [_touchbarControls count]; i++) {
            TjsTouch *touch = [[_touchbarControls objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: touch->identifier]) {
                TjsWidget *widget = (TjsWidget *)touch->userdata;

                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: touch->identifier];

                /* Create type */
                if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) { ///< TjsLabel
                    item.view = touch->view = [NSTextField labelWithString:
                        [NSString stringWithUTF8String: widget->value.asChar]];
                } else if (0 < (widget->flags & TJS_FLAG_TYPE_BUTTON)) { ///< TjsButton
                    item.view = touch->view = [NSButton buttonWithTitle:
                        [NSString stringWithUTF8String: widget->value.asChar]
                        target: self action: @selector(button:)];
                } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) { ///< TjsSlider
                    item.view = touch->view = [NSSlider sliderWithValue: widget->value.asInt
                        minValue: 0 maxValue: 100 target: self action: @selector(slider:)];
                } else {
                    continue;
                }

                [item.view setTag: i];

                /* Mark as ready and update it */
                touch->flags |= TJS_FLAG_READY;

                tjs_touch_update(touch->userdata);
            }
        }
    }

    return item;
}

/**
 * Handle application launch finish
 *
 * @param[inout]  aNotification  Notification sent to app
 **/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);

    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc]
        initWithIdentifier: kGroupButton];

    item.view = [NSButton buttonWithTitle:@"\U0001F4A9"
        target: self action: @selector(present:)];

    [NSTouchBarItem addSystemTrayItem:item];

    DFRElementSetControlStripPresenceForIdentifier(kGroupButton, YES);
}

/**
 * Handle application termination
 *
 * @param[inout]  aNotification  Notification sent to app
 **/

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_groupTouchBar release];

    _groupTouchBar = nil;

    /* Tidy up items */
    for (int i = 0; i < [_touchbarControls count]; i++) {
        TjsTouch *touch = [[_touchbarControls objectAtIndex: i] pointerValue];

        tjs_userdata_free(touch->userdata);
        free(touch);
    }
}
@end

/******************************
 *           Helper           *
 ******************************/

/**
 * Log handler
 *
 * @param[in]  loglevel  Log level
 * @param[in]  func      Name of the calling function
 * @param[in]  line      Line number of the call
 * @param[in]  fmt       Message format
 * @param[in]  ...       Variadic arguments
 **/

void tjs_log(int loglevel, const char *func, int line, const char *fmt, ...) {
    va_list ap;
    char buf[255];
    int guard;

    /* Get variadic arguments */
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    switch (loglevel) {
        case TJS_LOGLEVEL_INFO:
            NSLog(@"[INFO] %s", buf);
            break;
        case TJS_LOGLEVEL_ERROR:
            NSLog(@"[ERROR %s:%d] %s", func, line, buf);
            break;
        case TJS_LOGLEVEL_DEBUG:
            NSLog(@"[DEBUG %s:%d] %s", func, line, buf);
            break;
        case TJS_LOGLEVEL_DUK:
            NSLog(@"[DUK %s:%d] %s", func, line, buf);
    }
}

/**
 * Fatal error handler
 *
 * @param[in]  userdata  Userdata added to heap
 * @param[in]  msg       Message to log
 **/

void tjs_fatal(void *userdata, const char *msg) {
    (void) userdata; ///< Not unused anymore..

    TJS_LOG_DUK("Fatal error: %s", (msg ? msg : "No message"));

    abort();
}

/**
 * Helper to dump the duktape stack
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_dump_stack(const char *func, int line, duk_context *ctx) {
    duk_push_context_dump(ctx);

    TJS_LOG_DUK("%s", duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
}

/**
 * Terminate app
 **/

void tjs_exit() {
    [NSApp terminate: nil];
}

/******************************
 *           Touch            *
 ******************************/

/**
 * Find touchbar item based on userdata
 *
 * @param[in]  userdata  A #TjsUserdata
 *
 * @return Either found #TjsTouch; otherwise nil
 **/

static TjsTouch *tjs_touch_find(TjsUserdata *userdata) {
    for (int i = 0; i < [_touchbarControls count]; i++) {
        TjsTouch *touch = [[_touchbarControls objectAtIndex: i] pointerValue];

        if (touch->userdata == userdata) {
            return touch;
        }
    }

    return nil;
}

/**
 * Add item to touchbar
 *
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_touch_add(TjsUserdata *userdata) {
    if (nil != userdata) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);

        /* Create new touch */
        TjsTouch *touch = (TjsTouch *)calloc(1, sizeof(TjsTouch));

        touch->userdata = userdata;
        touch->identifier = [NSString stringWithFormat:
            @"org.subforge.control%lu", [_touchbarControls count]];

        /* Store in array */
        [_touchbarControls addObject: [NSValue value: &touch
            withObjCType: @encode(TjsTouch *)]];

        /* Store global in context */
        duk_push_this(_ctx);
        duk_put_global_string(_ctx, [touch->identifier UTF8String]);
    }
}

/**
 * Update color of touch item
 *
 * @param[inout]  touch  A #TjsTouch
 **/

static void tjs_touch_update_color(TjsTouch *touch) {
    TjsWidget *widget = (TjsWidget *)(touch->userdata);
    TjsColor *col = nil;

    /* Selct fg or bg */
    if (0 < (widget->flags & TJS_FLAG_UPDATE_COLOR_FG)) {
        col = &(widget->colors.fg);
    } else {
        col = &(widget->colors.bg);
    }

    /* Parse color */
    NSColor *parsedCol = [NSColor
        colorWithRed: ((float)(col->red) / 0xff)
        green: ((float)(col->green) / 0xff)
        blue: ((float)(col->blue) / 0xff)
        alpha: 1.0f];

    /* Handle widget types */
    if (0 < (widget->flags & TJS_FLAG_UPDATE_COLOR_FG)) {
        if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) {
            [((NSTextView *)(touch->view)) setTextColor: parsedCol];
        }
    } else {
        if (0 < (widget->flags & TJS_FLAG_TYPE_BUTTON)) {
            [((NSButton *)(touch->view)) setBezelColor: parsedCol];
        } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            [((NSSlider *)(touch->view)) setTrackFillColor: parsedCol];
            [((NSSlider *)(touch->view)) setNeedsDisplay];
        }
    }

    /* Remove flags */
    if (0 < (touch->flags & TJS_FLAG_READY)) {
        widget->flags &= ~TJS_FLAGS_COLORS;
    }
}

/**
 * Update value of touch item
 *
 * @param[inout]  touch  A #TjsTouch
 **/

static void tjs_touch_update_value(TjsTouch *touch) {
    TjsWidget *widget = (TjsWidget *)(touch->userdata);

    /* Handle widget types */
    if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
        [((NSSlider *)(touch->view)) setDoubleValue: widget->value.asInt];
    }

    /* Remove flags */
    if (0 < (touch->flags & TJS_FLAG_READY)) {
        widget->flags &= ~TJS_FLAG_UPDATE_VALUE;
    }
}

/**
 * Helper to update view based on state
 *
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_touch_update(TjsUserdata *userdata) {
    if (nil != userdata && 0 < (userdata->flags & TJS_FLAGS_WIDGETS)) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);

        /* Find touch */
        TjsTouch *touch = tjs_touch_find(userdata);

        if (nil != touch) {
            if (0 < (userdata->flags & TJS_FLAGS_COLORS)) {
                tjs_touch_update_color(touch);
            }
            if (0 < (userdata->flags & TJS_FLAG_UPDATE_VALUE)) {
                tjs_touch_update_value(touch);
            }
        }
    }
}

/**
 * Remove touchbar item based on userdata
 *
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_touch_remove(TjsUserdata *userdata) {
    if (nil != userdata) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);

        TjsTouch *touch = tjs_touch_find(userdata);

        if (nil != touch) {

        }
    }
}

/******************************
 *             I/O            *
 ******************************/

/**
 * Read file
 *
 * @param[in]  fileName  Name of file to load
 *
 * @return Read content
 **/

static char *tjs_read_file(NSString *fileName) {
    TJS_LOG_INFO("Loading file %s", [fileName UTF8String]);

    /* Load file */
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath: fileName];

    if (nil == file) {
        TJS_LOG_ERROR("Failed to open file file %s", [fileName UTF8String]);

        return nil;
    }

    /* Read and convert data */
    NSData *buffer = [file readDataToEndOfFile];

    NSString *data = [[NSString alloc] initWithData:buffer
        encoding:NSUTF8StringEncoding];

    [file closeFile];

    return (char *)[data UTF8String];
}

/**
 * Main entry point

 * @œparam{in}    argc  Number of arguments
 * @param[inout]  argv  Arguments array
 **/

int main(int argc, char *argv[]) {
    /* Create application */
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];

    _touchbarControls = [NSMutableArray arrayWithCapacity: 0];

    /* Create duk context */
    _ctx = duk_create_heap(nil, nil, nil, nil, tjs_fatal);

    /* Register functions */
    tjs_global_init(_ctx);
    tjs_command_init(_ctx);
    tjs_button_init(_ctx);
    tjs_label_init(_ctx);
    tjs_slider_init(_ctx);

    /* Source file if any */
    if (1 < argc) {
        NSString *fileName = [NSString stringWithUTF8String: argv[1]];

        char *buffer = tjs_read_file(fileName);

        if (buffer) {
            /* Just eval the content */
            TJS_LOG_INFO("Executing file %s", argv[1]);

            duk_eval_string_noresult(_ctx, buffer);
        }
    }

    /* Create and run application */
    AppDelegate *del = [[AppDelegate alloc] init];

    [NSApp setDelegate: del];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp run];

    /* Tidy up */
    duk_destroy_heap(_ctx);

    return 0;
}