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

    item.view = [NSButton buttonWithTitle:@"\U0001F4A9\U0001F4A9" 
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
 * Create touchbar button from JS
 **/

static duk_ret_t duk_create_button(duk_context *ctx) {
    const char *title = duk_safe_to_string(_ctx, -1);

    /* Create new button */
    DukButton *button = (DukButton *)calloc(1, sizeof(DukButton));

    button->idx = [_items count];
    button->title = [NSString stringWithUTF8String: title];
    button->identifier = [NSString stringWithFormat: 
        @"org.subforge.b%d", button->idx];
    
    [_items addObject: [NSValue value: &button withObjCType: @encode(DukButton *)]];

    NSLog(@"duk_create_button: name=%@, idx=%d", button->title, button->idx);

    duk_push_int(_ctx, button->idx);

    return 1;
}

/**
 * Add button to touchbar from JS
 **/

static duk_ret_t duk_bind_button(duk_context *ctx) {
    int idx = duk_require_int(_ctx, 0);

    NSLog(@"duk_bind_button: idx=%d",  idx);
    
    DukButton *button = [[_items objectAtIndex: idx] pointerValue];

    if (nil != button) {
        NSLog(@"duk_bind_button: name=%@, idx=%d",  button->title, button->idx);
        
        duk_require_function(_ctx, 1);
        duk_dup_top(_ctx);
        duk_put_global_string(_ctx, [button->identifier UTF8String]);
    }

    return 0;
}

/**
 * Print string from JS
 **/

static duk_ret_t duk_print(duk_context *ctx) {
    /* Join string on stack */
	duk_push_string(_ctx, " ");
	duk_insert(_ctx, 0);
	duk_join(_ctx, duk_get_top(ctx) - 1);

    NSLog(@"duk_print: %s", duk_safe_to_string(_ctx, -1));

    return 0;
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
    duk_push_c_function(_ctx, duk_create_button, 1);
    duk_put_global_string(_ctx, "duk_create_button");
    duk_push_c_function(_ctx, duk_bind_button, 2);
    duk_put_global_string(_ctx, "duk_bind_button");
    duk_push_c_function(_ctx, duk_print, DUK_VARARGS);
    duk_put_global_string(_ctx, "duk_print");

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
