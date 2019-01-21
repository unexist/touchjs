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

#include "duktape/duktape.h"

/* Symbols */
#define TJS_SYM_CLICK_CB "__click_cb"
#define TJS_SYM_USERDATA "__userdata"

/* Macros */
#define TJS_DSTACK(CTX) \
    tjs_dump_stack(__FUNCTION__, __LINE__, CTX);
#define TJS_LOG(FMT, ...) \
    tjs_log(__FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_DEBUG \
    NSLog(@"DEBUG %s:%d", __FUNCTION__, __LINE__);

/* Flags */
#define TJS_FLAG_TYPE_BUTTON (1L << 0)
#define TJS_FLAG_TYPE_LABEL  (1L << 1)

#define TJS_FLAG_COLOR_FG (1L << 5)
#define TJS_FLAG_COLOR_BG (1L << 6)

/* Globals */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

NSTouchBar *_groupTouchBar;
NSMutableArray *_touchbarControls;
duk_context *_ctx;

/* Internal struct */
typedef struct tjs_color_t {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} TjsColor;

typedef struct tjs_control_t {
    int flags;
    int idx;
    char *callback;
    char *title;

    struct {
        struct tjs_color_t fg;
        struct tjs_color_t bg;
    } colors;

    /* Obj-c */
    NSTouchBarItemIdentifier identifier;
    NSView *view;
} TjsControl;

/* Forward declarations */
static void tjs_dump_stack(const char *func, int line, duk_context *ctx);
static void tjs_control_helper_update(TjsControl *control);
static void tjs_button_helper_click(duk_context *ctx);

@implementation AppDelegate

/**
 * Handle group touchbar
 **/

- (NSTouchBar *)groupTouchBar {
    NSMutableArray *array;

    NSLog(@"groupTouchbar");

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
        TjsControl *control = [[_touchbarControls objectAtIndex: i] pointerValue];

        [array addObject: control->identifier];
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
 * Handle send
 **/

- (void)button:(id)sender {
    int idx = [sender tag];

    TjsControl *control = [[_touchbarControls objectAtIndex: idx] pointerValue];

    if (nil != control) {
        NSLog(@"idx=%d, name=%s", control->idx, control->title);

        /* Get object and call click */
        duk_get_global_string(_ctx, [control->identifier UTF8String]);

        TJS_DSTACK(_ctx);

        if (duk_is_object(_ctx, -1)) {
            tjs_button_helper_click(_ctx);
        }
    }
}

/**
 * Handle send
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
            action:@selector(terminate:)];
    } else {
        /* Create custom controls */
        for (int i = 0; i < [_touchbarControls count]; i++) {
            TjsControl *control = [[_touchbarControls objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: control->identifier]) {
                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: control->identifier];

                /* Create type */
                if (0 < (control->flags & TJS_FLAG_TYPE_BUTTON)) {
                    item.view = control->view = [NSButton buttonWithTitle:
                        [NSString stringWithUTF8String: control->title]
                        target: self action: @selector(button:)];
                } else if (0 < (control->flags & TJS_FLAG_TYPE_LABEL)) {
                   item.view = control->view = [NSTextField labelWithString:
                        [NSString stringWithUTF8String: control->title]];
                }

                tjs_control_helper_update(control);

                [item.view setTag: i];
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);

    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc]
        initWithIdentifier:kGroupButton];

    item.view = [NSButton buttonWithTitle:@"\U0001F4A9"
        target:self action:@selector(present:)];

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
        TjsControl *control = [[_touchbarControls objectAtIndex: i] pointerValue];

        free(control->title);
        free(control);
    }
}
@end

/******************************
 *           Helper           *
 ******************************/

/**
 * Log handler
 *
 * @param[in]  func  Name of the calling function
 * @param[in]  line  Line number of the call
 * @param[in]  fmt   Message format
 * @param[in]  ...   Variadic arguments
 **/

static void tjs_log(const char *func, int line, const char *fmt, ...) {
    va_list ap;
    char buf[255];
    int guard;

    /* Get variadic arguments */
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    NSLog(@"%s@%d: %s", func, line, buf);
}

/**
 * Fatal error handler
 *
 * @param[in]  userdata  Userdata added to heap
 * @param[in]  msg       Message to log
 **/

static void tjs_fatal(void *userdata, const char *msg) {
    (void) userdata; ///< Not unused anymore..

    NSLog(@"*** FATAL ERROR: %s", (msg ? msg : "No message"));

    abort();
}

/**
 * Helper to dump the duktape stack
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_dump_stack(const char *func, int line, duk_context *ctx) {
    duk_push_context_dump(ctx);

    NSLog(@"%s@%d: %s", func, line, duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
}

/*******************************
 *           Control           *
 *******************************/

/**
 * Helper to create userdata
 *
 * @param[inout]  ctx    A #duk_context
 * @param[in]     flags  Control flags
 * @param[inout]  title. Title of the control
 *
 * @return Either #TjsControl on success; otherwise #null
 **/

 static TjsControl *tjs_control_userdata_new(duk_context *ctx, int flags, const char *title) {
    /* Create new control */
    TjsControl *control = (TjsControl *)calloc(1, sizeof(TjsControl));

    control->flags = flags;
    control->idx = [_touchbarControls count];
    control->title = strdup(title);
    control->identifier = [NSString stringWithFormat:
        @"org.subforge.control%d", control->idx];

    /* Store in array */
    [_touchbarControls addObject: [NSValue value: &control
        withObjCType: @encode(TjsControl *)]];

    /* Store pointer ref */
    duk_push_this(ctx);
    duk_push_pointer(ctx, (void *) control);
    duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_USERDATA);
    duk_pop(ctx);

    TJS_LOG("flags=%d, idx=%d, title=%s", control->flags, control->idx, control->title);

    return control;
 }

/**
 * Helper to get control userdata from duktape
 *
 * @param[inout]  ctx  A #duk_context
 *
 * @return Either #TjsControl on success; otherwise #null
 **/

static TjsControl *tjs_control_userdata_get(duk_context *ctx) {
    /* Get userdata */
    duk_push_this(ctx);
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_USERDATA);

    TjsControl *control = (TjsControl *)duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);

    return control;
}

/**
 * Helper to update view based on state
 *
 * @param[inout]  control  A #TjsControl
 **/

static void tjs_control_helper_update(TjsControl *control) {
    if (nil != control) {
        /* Set fg color if any */
        if (0 < (control->flags & TJS_FLAG_COLOR_FG)) {
            NSColor *fgColor = [NSColor
                colorWithDeviceRed: (control->colors.fg.red / 0xff)
                green: (control->colors.fg.green / 0xff)
                blue: (control->colors.fg.blue / 0xff)
                alpha: 1.0f];

            /* Handle control types */
            if (0 < (control->flags & TJS_FLAG_TYPE_LABEL)) {
                [(NSTextView *)control->view setTextColor: fgColor];
            }
        }

        /* Set bg color if any */
        if (0 < (control->flags & TJS_FLAG_COLOR_BG)) {
            NSColor *bgColor = [NSColor
                colorWithDeviceRed: (control->colors.bg.red / 0xff)
                green: (control->colors.bg.green / 0xff)
                blue: (control->colors.bg.blue / 0xff)
                alpha: 1.0f];

            /* Handle control types */
            if (0 < (control->flags & TJS_FLAG_TYPE_BUTTON)) {
                [((NSButton *)(control->view)) setBezelColor: bgColor];
            }
        }
    }
}

 /**
  * Native button to string prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_control_helper_tostring(duk_context *ctx) {
    duk_push_this(ctx);

    /* Get idx */
    duk_get_prop_string(ctx, -1, "idx");
    int idx = duk_get_int(ctx, -1);

    /* Get title */
    duk_get_prop_string(ctx, -2, "title");
    const char *title = duk_get_string(ctx, -1);

    duk_push_sprintf(ctx, "%s %d", title, idx);

    return 1;
}

 /**
  * Helper to set the control color
  *
  * @param[inout]  ctx   A #duk_context
  * @param[in]     flag  Color flag
  **/

static duk_ret_t tjs_control_helper_setcolor(duk_context *ctx, int flag) {
    /* Fetch colors from stack */
    int blue = duk_require_int(ctx, -1);
    int green = duk_require_int(ctx, -2);
    int red = duk_require_int(ctx, -3);

    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s, red=%d, green=%d, blue=%d",
            control->idx, control->title, red, green, blue);

        /* Store color in case control isn't visible */
        TjsColor *color = nil;
        control->flags |= flag;

        if (TJS_FLAG_COLOR_FG == flag) {
            color = &(control->colors.fg);
        } else {
            color = &(control->colors.bg);
        }

        color->red = red;
        color->green = green;
        color->blue = blue;

        tjs_control_helper_update(control);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native control setColor method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_control_prototype_setfgcolor(duk_context *ctx) {
    return tjs_control_helper_setcolor(ctx, TJS_FLAG_COLOR_FG);
}

 /**
  * Native control setColor prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_control_prototype_setbgcolor(duk_context *ctx) {
    return tjs_control_helper_setcolor(ctx, TJS_FLAG_COLOR_BG);
}

/**
 * Native button destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_control_dtor(duk_context *ctx) {
    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);
    }

    return 0;
}

/**
 * Native control constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_control_ctor(duk_context *ctx, int flags) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    const char *title = duk_require_string(ctx, -1);
    duk_pop(ctx);

    /* Create new userdata */
    TjsControl *control = tjs_control_userdata_new(ctx, flags, title);

    /* Set properties */
    duk_push_this(ctx);
    duk_push_int(ctx, control->idx);
    duk_put_prop_string(ctx, -2, "idx");
    duk_push_string(ctx, control->title);
    duk_put_prop_string(ctx, -2, "title");

    /* Register destructor */
    duk_push_c_function(ctx, tjs_control_dtor, 0);
    duk_set_finalizer(ctx, -2);

    /* Store object */
    const char *identifier = [control->identifier UTF8String];

    duk_push_this(ctx);
    duk_put_global_string(ctx, identifier);

    TJS_LOG("type=%d, idx=%d, name=%s",
        control->flags, control->idx, control->title);

    return 0;
}

/******************************
 *           Button           *
 ******************************/

 /**
  * Native button click prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static void tjs_button_helper_click(duk_context *ctx) {
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_CLICK_CB);

    /* Call if callable */
    if (duk_is_callable(ctx, -1)) {
        duk_swap_top(ctx, -2);
        duk_pcall_method(ctx, 0);
        duk_pop(ctx); ///< Ignore result
    }
}

 /**
 * Native button constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_ctor(duk_context *ctx) {
    return tjs_control_ctor(ctx, TJS_FLAG_TYPE_BUTTON);
}

/**
 * Native button bind prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_prototype_bind(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);

    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);

        /* Store click callback */
        duk_push_this(ctx);
        duk_swap_top(ctx, -2);
        duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_CLICK_CB);
        duk_pop(ctx);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
  * Native button click prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_prototype_click(duk_context *ctx) {
    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);

        /* Call click callback */
        duk_push_this(ctx);
        tjs_button_helper_click(ctx);
  }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native button print prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_prototype_print(duk_context *ctx) {
    tjs_control_helper_tostring(ctx);

    TJS_LOG("%s", duk_safe_to_string(ctx, -1));

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Init methods for #Tjsbutton
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_button_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_button_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_button_prototype_bind, 1);
    duk_put_prop_string(ctx, -2, "bind");

    duk_push_c_function(ctx, tjs_button_prototype_click, 0);
    duk_put_prop_string(ctx, -2, "click");

    duk_push_c_function(ctx, tjs_button_prototype_print, 0);
    duk_put_prop_string(ctx, -2, "print");

    duk_push_c_function(ctx, tjs_control_prototype_setbgcolor, 3);
    duk_put_prop_string(ctx, -2, "setBgColor");

    duk_push_c_function(ctx, tjs_control_helper_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsButton");
}

/*****************************
 *           Label  *        *
 *****************************/

/**
 * Native label constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_label_ctor(duk_context *ctx) {
    return tjs_control_ctor(ctx, TJS_FLAG_TYPE_LABEL);
}

/**
 * Init methods for #TjsLabel
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_label_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_label_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_control_prototype_setfgcolor, 3);
    duk_put_prop_string(ctx, -2, "setFgColor");

    duk_push_c_function(ctx, tjs_control_helper_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsLabel");
}

/**
 * Native print method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_print(duk_context *ctx) {
    /* Join strings on stack */
	duk_push_string(ctx, " ");
	duk_insert(ctx, 0);
	duk_join(ctx, duk_get_top(ctx) - 1);

    TJS_LOG("%s", duk_safe_to_string(ctx, -1));

    return 0;
}

/**
 * Native rgb method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_rgb(duk_context *ctx) {
    /* Sanitize value */
    const char *hexcode = duk_require_string(ctx, -1);
    duk_pop(ctx);

    if ('#' != hexcode[0]) {
        return duk_error(ctx, DUK_ERR_TYPE_ERROR, "Invalid argument value: '%s'", hexcode);
    }

    /* Convert string to hex */
    unsigned int color = 0;

    NSScanner *scanner = [NSScanner scannerWithString:
        [NSString stringWithUTF8String: ++hexcode]]; ///< Skip prefix #

    [scanner scanHexInt: &color];

    /* Mask color values */
    unsigned char red = (unsigned char)(color >> 16);
    unsigned char green = (unsigned char)(color >> 8);
    unsigned char blue = (unsigned char)(color);

    /* Push array */
    duk_idx_t idx = duk_push_array(ctx);

    duk_push_number(ctx, red);
    duk_put_prop_index(ctx, idx, 0);
    duk_push_number(ctx, green);
    duk_put_prop_index(ctx, idx, 1);
    duk_push_number(ctx, blue);
    duk_put_prop_index(ctx, idx, 2);

    TJS_DSTACK(ctx);

    return 1;
}

/**
 * Native quit method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_quit(duk_context *ctx) {
    TJS_LOG("Exiting");

    [NSApp terminate: nil];

    return 0;
}

/**
 * Init methods for global
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_global_init(duk_context *ctx) {
    /* Register methods */
    duk_push_c_function(ctx, tjs_global_print, DUK_VARARGS);
    duk_put_global_string(ctx, "tjs_print");

    duk_push_c_function(ctx, tjs_global_rgb, 1);
    duk_put_global_string(ctx, "tjs_rgb");

    duk_push_c_function(ctx, tjs_global_quit, 0);
    duk_put_global_string(ctx, "tjs_quit");
}

/**
 * Read file
 *
 * @param[in]  fileName  Name of file to load
 *
 * @return Read content
 **/

static char* readFileToCString(NSString *fileName) {
    NSLog(@"Loading file %@", fileName);

    /* Load file */
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath: fileName];

    if (file == nil) {
        NSLog(@"Failed to open file %@", fileName);

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
    tjs_label_init(_ctx);
    tjs_button_init(_ctx);
    tjs_global_init(_ctx);

    /* Source file if any */
    if (1 < argc) {
        NSString *fileName = [NSString stringWithUTF8String: argv[1]];

        char *buffer = readFileToCString(fileName);

        if (buffer) {
            /* Just eval the content */
            NSLog(@"Executing file %@", fileName);

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
