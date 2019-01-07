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

/* Globals */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

NSTouchBar *_groupTouchBar;
NSMutableArray *_items;
duk_context *_ctx;

/* Internal struct */
typedef struct dukbutton_t {
    int idx;
    char *callback;
    NSString *title;
    NSTouchBarItemIdentifier identifier;
} DukButton;

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
        DukButton *button = [[_items objectAtIndex: i] pointerValue];

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

    DukButton *button = [[_items objectAtIndex: idx] pointerValue];

    if (nil != button) {
        NSLog(@"button: name=%@, idx=%d", button->title, button->idx);

        duk_get_global_string(_ctx, [button->identifier UTF8String]);
        duk_push_int(_ctx, idx);
        duk_pcall(_ctx, 1);
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
            DukButton *button = [[_items objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: button->identifier]) {
                item = [[NSCustomTouchBarItem alloc] 
                    initWithIdentifier: button->identifier];

                item.view = [NSButton buttonWithTitle: button->title
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
        DukButton *button = [[_items objectAtIndex: i] pointerValue];

        free(button);
    }
}
@end

/**
 * Native button constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_ctor(duk_context *ctx) {
    /* Get arguments */
    const char *title = duk_require_string(_ctx, -1);
    int idx = [_items count];

    /* Set properties */
    duk_push_this(ctx);
    duk_push_int(ctx, idx);
    duk_put_prop_string(ctx, -2, "idx");
    duk_push_string(ctx, title);
    duk_put_prop_string(ctx, -2, "title");

    /* Create new button */
    DukButton *button = (DukButton *)calloc(1, sizeof(DukButton));

    button->idx = [_items count];
    button->title = [NSString stringWithUTF8String: title];
    button->identifier = [NSString stringWithFormat: 
        @"org.subforge.b%d", button->idx];

    /* Store pointer ref on stash */
    duk_push_global_stash(ctx);
    duk_push_pointer(ctx, (void *) button);
    duk_put_prop_string(ctx, -2, "userdata"):
    
    /* Store button in array */
    [_items addObject: [NSValue value: &button 
        withObjCType: @encode(DukButton *)]];

    NSLog(@"tjs_button_constructor: name=%@, idx=%d", 
        button->title, button->idx);

    return 0;
}

/**
 * Native button destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_dtor(duk_context *ctx) {
    /* Nothing to do yet */
}

/**
 * Native button event binder
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_bind(duk_context *ctx) {
    int idx = duk_require_int(_ctx, 0);

    NSLog(@"duk_bind_button: idx=%d",  idx);
    
    DukButton *button = [[_items objectAtIndex: idx] pointerValue];

    if (nil != button) {
        NSLog(@"duk_bind_button: name=%@, idx=%d", 
            button->title, button->idx);
        
        duk_require_function(_ctx, 1);
        duk_dup_top(_ctx);
        duk_put_global_string(_ctx, [button->identifier UTF8String]);
    }

    return 0;
}

 /**
  * Native button printer
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_print(duk_context *ctx) {
    duk_push_this(ctx);

    /* Get idx */
    duk_get_prop_string(ctx, -1, "idx");
    int idx = duk_to_int(ctx, -1);

    /* Get title */
    duk_get_prop_string(ctx, -1, "title");
    const char *title = duk_safe_to_string(ctx, -1);

    NSLog(@"tjs_button_print: name=%@, idx=%d", title, idx);

    return 0;
}

/**
 * Init button
 **/

static void tjs_button_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_button_ctor, 1);
    duk_push_object(ctx);

    /* Register destructor */
    duk_push_c_function(ctx, tjs_button_dtor);
    duk_set_finalizer(ctx, -2);

    /* Register methods */
    duk_push_c_function(ctx, tjs_button_bind, 1);
    duk_put_prop_string(ctx, -2 "bind")

    duk_push_c_function(ctx, tjs_button_print, 1);
    duk_put_prop_string(ctx, -2 "print")
}

/**
 * Print string from JS
 **/

static duk_ret_t tjs_global_print(duk_context *ctx) {
    /* Join string on stack */
	duk_push_string(_ctx, " ");
	duk_insert(_ctx, 0);
	duk_join(_ctx, duk_get_top(ctx) - 1);

    NSLog(@"tjs_print: %s", duk_safe_to_string(_ctx, -1));

    return 0;
}

static void tjs_global_init(duk_context *ctx) {
    duk_push_c_function(ctx, tjx_global_print, DUK_VARARGS);
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
    tjs_button_init(ctx);
    tjs_global_init();

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
