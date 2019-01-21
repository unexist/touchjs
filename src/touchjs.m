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
 * Handle send event: button
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
 * Handle send event: button
 **/

- (void)slider:(id)sender {
    int idx = [sender tag];
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
            action:@selector(terminate:)];
    } else {
        /* Create custom controls */
        for (int i = 0; i < [_touchbarControls count]; i++) {
            TjsControl *control = [[_touchbarControls objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: control->identifier]) {
                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: control->identifier];

                /* Create type */
                if (0 < (control->flags & TJS_FLAG_TYPE_BUTTON)) { ///< TjsButton
                    item.view = control->view = [NSButton buttonWithTitle:
                        [NSString stringWithUTF8String: control->title]
                        target: self action: @selector(button:)];
                } else if (0 < (control->flags & TJS_FLAG_TYPE_LABEL)) { ///< TjsLabel
                   item.view = control->view = [NSTextField labelWithString:
                        [NSString stringWithUTF8String: control->title]];
                } else if (0 < (control->flags & TJS_FLAG_TYPE_SLIDER)) { ///< TjsSlider
                   item.view = control->view = [NSSlider sliderWithValue: 0 minValue: 0
                        maxValue: 100 target: self action: @selector(slider:)];
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

void tjs_log(const char *func, int line, const char *fmt, ...) {
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

void tjs_fatal(void *userdata, const char *msg) {
    (void) userdata; ///< Not unused anymore..

    NSLog(@"*** FATAL ERROR: %s", (msg ? msg : "No message"));

    abort();
}

/**
 * Helper to dump the duktape stack
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_dump_stack(const char *func, int line, duk_context *ctx) {
    duk_push_context_dump(ctx);

    NSLog(@"%s@%d: %s", func, line, duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
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
    tjs_button_init(_ctx);
    tjs_label_init(_ctx);
    tjs_slider_init(_ctx);
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
