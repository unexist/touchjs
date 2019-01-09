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
    tjs_log(__FUNCTION__, __LINE__, FMT, __VA_ARGS__);

/* Globals */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

NSTouchBar *_groupTouchBar;
NSMutableArray *_items;
duk_context *_ctx;

/* Internal struct */
typedef struct tjs_button_t {
    int idx;
    char *callback;
    char *title;
    NSTouchBarItemIdentifier identifier;
} TjsButton;

@implementation AppDelegate

/**
 * Handle group touchbar
 **/

- (NSTouchBar *)groupTouchBar {
    NSLog(@"groupTouchbar");

    /* Create if required */
    if (!_groupTouchBar) {
        NSTouchBar *groupTouchBar = [[NSTouchBar alloc] init];

        groupTouchBar.delegate = self;

        _groupTouchBar = groupTouchBar;
    }

    /* Collect identifiers */
    NSMutableArray *array = [NSMutableArray arrayWithCapacity: 1];

    for (int i = 0; i < [_items count]; i++) {
        TjsButton *button = [[_items objectAtIndex: i] pointerValue];

        [array addObject: button->identifier];
    }

    [array addObject: kQuit];

    _groupTouchBar.defaultItemIdentifiers = array;

    return _groupTouchBar;
}

/**
 * Set group touch bar
 **/

-(void)setGroupTouchBar:(NSTouchBar*)bar {
    _groupTouchBar = bar;
}

/**
 * Handle send
 **/

- (void)button:(id)sender {
    int idx = [sender tag];

    TjsButton *button = [[_items objectAtIndex: idx] pointerValue];

    if (nil != button) {
        NSLog(@"%s: idx=%d, name=%s", __FUNCTION__,
            button->idx, button->title);

        /* Call callback */
        duk_get_global_string(_ctx,
            [button->identifier UTF8String]);
        duk_pcall(_ctx, 0);
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
        /* Check custom buttons */
        for (int i = 0; i < [_items count]; i++) {
            TjsButton *button = [[_items objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: button->identifier]) {
                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: button->identifier];

                item.view = [NSButton buttonWithTitle:
                    [NSString stringWithUTF8String: button->title]
                    target: self action: @selector(button:)];

                [item.view setTag: i];
            }
        }
    }

    NSLog(@"makeItemForIdentifier");

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
    for (int i = 0; i < [_items count]; i++) {
        TjsButton *button = [[_items objectAtIndex: i] pointerValue];

        free(button->title);
        free(button);
    }
}
@end

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
 * Helper to dump the duktape stack
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_dump_stack(const char *func, int line, duk_context *ctx) {
    duk_push_context_dump(ctx);

    NSLog(@"%s@%d: %s", func, line, duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
}

/**
 * Native button destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_dtor(duk_context *ctx) {
    duk_push_this(ctx);

    /* Get userdata */
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_USERDATA);

    TjsButton *button = (TjsButton *)duk_get_pointer(ctx, -1);

    TJS_LOG("idx=%d, name=%s", button->idx, button->title);

    return 0;
}

/**
 * Native button constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    const char *title = duk_require_string(ctx, -1);
    duk_pop(ctx);

    /* Create new button */
    TjsButton *button = (TjsButton *)calloc(1, sizeof(TjsButton));

    button->idx = [_items count];
    button->title = strdup(title);
    button->identifier = [NSString stringWithFormat:
        @"org.subforge.b%d", button->idx];

    /* Set properties */
    duk_push_this(ctx);
    duk_push_int(ctx, button->idx);
    duk_put_prop_string(ctx, -2, "idx");
    duk_push_string(ctx, button->title);
    duk_put_prop_string(ctx, -2, "title");

    /* Register destructor */
    duk_push_c_function(ctx, tjs_button_dtor, 0);
    duk_set_finalizer(ctx, -2);

    /* Store pointer ref */
    duk_push_pointer(ctx, (void *) button);
    duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_USERDATA);

    /* Store button in array */
    [_items addObject: [NSValue value: &button
        withObjCType: @encode(TjsButton *)]];

    TJS_LOG("idx=%d, name=%s", button->idx, button->title);

    return 0;
}

/**
 * Helper to get button userdata
 *
 * @param[inout]  ctx  A #duk_context
 *
 * @return Either #TjsButton on success; otherwise #null
 **/

static TjsButton *tjs_button_get_userdata(duk_context *ctx) {
    /* Get userdata */
    duk_push_this(ctx);
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_USERDATA);

    TjsButton *button = (TjsButton *)duk_get_pointer(ctx, -1);
    duk_pop(ctx);

    return button;
}

/**
 * Native button bind method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_bind(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);

    /* Get userdata */
    TjsButton *button = tjs_button_get_userdata(ctx);

    if (nil != button) {
        TJS_LOG("idx=%d, name=%s", button->idx, button->title);

        /* Store click callback */
        duk_swap_top(ctx, -2);
        duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_CLICK_CB);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
  * Native button click method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_click(duk_context *ctx) {
    /* Get userdata */
    TjsButton *button = tjs_button_get_userdata(ctx);

    if (nil != button) {
        TJS_LOG("idx=%d, name=%s", button->idx, button->title);

        /* Get click callback */
        duk_push_this(ctx);
        duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_CLICK_CB);

        /* Call if callable */
        if (duk_is_callable(ctx, -1)) {
            duk_push_this(ctx); ///< Add this
            duk_pcall_method(ctx, 0);
            duk_pop(ctx); ///< Ignore result
        }
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native button print method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_print(duk_context *ctx) {
    duk_push_this(ctx);

    /* Get idx */
    duk_get_prop_string(ctx, -1, "idx");
    int idx = duk_get_int(ctx, -1);

    /* Get title */
    duk_get_prop_string(ctx, -2, "title");
    const char *title = duk_get_string(ctx, -1);

    TJS_LOG("idx=%d, name=%s", idx, title);

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Init methods for #TjsButton
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_button_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_button_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_button_bind, 1);
    duk_put_prop_string(ctx, -2, "bind");

    duk_push_c_function(ctx, tjs_button_click, 0);
    duk_put_prop_string(ctx, -2, "click");

    duk_push_c_function(ctx, tjs_button_print, 0);
    duk_put_prop_string(ctx, -2, "print");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsButton");
}

/**
 * Native print method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_print(duk_context *ctx) {
    /* Join string on stack */
	duk_push_string(ctx, " ");
	duk_insert(ctx, 0);
	duk_join(ctx, duk_get_top(ctx) - 1);

    TJS_LOG("%s", duk_safe_to_string(ctx, -1));

    return 0;
}

/**
 * Init methods for global
 *
 * @param[inout]  ctx  A #duk_context
 **/

static void tjs_global_init(duk_context *ctx) {
    duk_push_c_function(ctx, tjs_global_print, DUK_VARARGS);
    duk_put_global_string(ctx, "tjs_print");
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

    _items = [NSMutableArray arrayWithCapacity: 0];

    /* Create duk context */
    _ctx = duk_create_heap_default();

    /* Register functions */
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
