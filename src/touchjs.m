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

#import <Cocoa/Cocoa.h>

#include <unistd.h>
#include "touchjs.h"

/* Constants */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

/* Types */
typedef struct tjs_embed_t {
    int flags;

    struct tjs_userdata_t *userdata;
    struct tjs_userdata_t *parent;

    /* Obj-c */
    NSTouchBarItemIdentifier identifier;
    NSView *view;
} TjsEmbed;

typedef struct tjs_touch_t {
    int flags;
    int loglevel;

    duk_context *ctx;

    /* Obj-c */
    NSTouchBar *bar;
    NSMutableArray *embedded;
} TjsTouch;

typedef union tjs_packed_t {
    unsigned char data[2];
    unsigned int packed;
} TjsPack;

/* Globals */
TjsTouch touch;

/* Forward declarations */
extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

static TjsEmbed *tjs_find(TjsUserdata *userdata, int *idx);
static void tjs_embed_configure(TjsEmbed *embed);
static void tjs_embed_update(TjsEmbed *embed);
static void tjs_embed_color(TjsEmbed *embed);
static void tjs_embed_value(TjsEmbed *embed);

/* Interfaces */
@interface NSTouchBarItem ()
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
@end

@interface NSTouchBar ()
/* macOS 10.14 and above */
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

/* macOS 10.13 and below */
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTouchBarDelegate>
@end

@implementation AppDelegate

/**
 * Handle group touchbar
 **/

- (NSTouchBar *)groupTouchBar {
    NSMutableArray *array;

    /* Create if required */
    if (!touch.bar) {
        NSTouchBar *groupTouchBar = [[NSTouchBar alloc] init];

        array = [NSMutableArray arrayWithCapacity: 1];

        groupTouchBar.delegate = self;
        groupTouchBar.defaultItemIdentifiers = array;

        touch.bar = groupTouchBar;
    } else {
        //array = (NSMutableArray *)touch.bar.defaultItemIdentifiers;

        //[array removeAllObjects];
        array = [NSMutableArray arrayWithCapacity: 1];
    }

    /* Collect identifiers */
    for (int i = 0; i < [touch.embedded count]; i++) {
        TjsEmbed *embed = [[touch.embedded objectAtIndex: i] pointerValue];

        /* Exclude items with a parent */
        if (NULL == embed->parent) {
            [array addObject: embed->identifier];
        }
    }

    [array addObject: kQuit];

    touch.bar.defaultItemIdentifiers = array;

    return touch.bar;
}

/**
 * Set group touch bar
 *
 * @param[inout]  touchBar  Touchbar to add to window
 **/

-(void)setGroupTouchBar:(NSTouchBar*)touchBar {
    touch.bar = touchBar;
}

/**
 * Handle send event: button
 *
 * @param[in]  sender  Sender of this event
 **/

- (void)button:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsEmbed *embed = [[touch.embedded objectAtIndex: idx] pointerValue];

    if (NULL != embed && NULL != embed->userdata) {
        NSString *identifier;

        TJS_LOG_DEBUG("flags=%d, idx=%d", embed->userdata->flags, idx);

        /* Get object and call callback if any */
        duk_get_global_string(touch.ctx, [embed->identifier UTF8String]);

        if (duk_is_object(touch.ctx, -1)) {
            tjs_super_callback_call(touch.ctx, TJS_SYM_CLICK_CB, 0);
        } else {
            duk_pop(touch.ctx);
        }
    }
}

/**
 * Handle send event: slider
 *
 * @param[in]  sender  Sender of this event
 **/

- (void)slider:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsEmbed *embed = [[touch.embedded objectAtIndex: idx] pointerValue];

    if (NULL != embed && NULL != embed->userdata) {
        TjsWidget *widget = (TjsWidget *)embed->userdata;

        /* Update value */
        NSSlider *slider = (NSSlider *)sender;

        double value = [slider doubleValue];

        if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            widget->value.asInt = value;
        }

        TJS_LOG_DEBUG("obj=%p, flags=%d, idx=%d, value=%lu",
            widget, widget->flags, idx, value);

        /* Get object and call callback */
        duk_get_global_string(touch.ctx, [embed->identifier UTF8String]);

        if (duk_is_object(touch.ctx, -1)) {
            duk_push_int(touch.ctx, value);
            tjs_super_callback_call(touch.ctx, TJS_SYM_SLIDE_CB, 1);
        } else {
            duk_pop(touch.ctx);
        }
    }
}

/**
 * Handle send event: present
 *
 * @param[in]  sender  Sender of this event
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
 *
 * @param[in]  identifier  Touch item identifier
 **/

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
       makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSCustomTouchBarItem *item = NULL;

    /* Check identifiers */
    if ([identifier isEqualToString: kQuit]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier: kQuit];

        item.view = [NSButton buttonWithTitle:@"Quit"
            target:[NSApplication sharedApplication]
            action: @selector(terminate:)];
    } else {
        /* Create custom controls */
        for (int i = 0; i < [touch.embedded count]; i++) {
            TjsEmbed *embed = [[touch.embedded objectAtIndex: i] pointerValue];

            if ([identifier isEqualToString: embed->identifier]) {
                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: embed->identifier];

                tjs_embed_configure(embed);
                tjs_embed_update(embed);

                item.view = embed->view;
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
    [touch.bar release];

    touch.bar = NULL;

    /* Tidy up items */
    for (int i = 0; i < [touch.embedded count]; i++) {
        TjsEmbed *embed = [[touch.embedded objectAtIndex: i] pointerValue];

        tjs_userdata_free(embed->userdata);
        free(embed);
    }
}
@end

/******************************
 *           Helper           *
 ******************************/

 /**
  * Print usage info
  **/

 static void tjs_usage(void) {
    NSLog(@"Usage: %s [OPTIONS]\n\n" \
           "Options:\n" \
           "  -f FILE           Eval file \n" \
           "  -h                Show this help and exit\n" \
           "  -v                Show version info and exit\n" \
           "  -l LEVEL[,LEVEL]  Set logging levels (\n" \
           "  -d                Print debugging messages\n" \
           "\nPlease report bugs at %s\n",
        PKG_NAME, PKG_BUGREPORT);
}

/**
 * Print version info
 **/

static void tjs_version(void) {
  NSLog(@"%s v%s - Copyright (c) 2019 Christoph Kappel\n" \
         "Released under the GNU General Public License\n",
        PKG_NAME, PKG_VERSION);
}

/**
 * Log handler
 *
 * @param[in]  level  Log level
 * @param[in]  func   Name of the calling function
 * @param[in]  line   Line number of the call
 * @param[in]  fmt    Message format
 * @param[in]  ...    Variadic arguments
 **/

void tjs_log(int level, const char *func, int line, const char *fmt, ...) {
    va_list ap;
    char buf[255];
    int guard;

    /* Check loglevel */
    if(0 == (touch.loglevel & level)) return;

    /* Get variadic arguments */
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    switch (level) {
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
 * Parse loglevel string
 *
 * @param[in]  str  Loglevel string
 *
 * @return Parsed loglevel
 **/

static int tjs_level(const char *str) {
    int level = 0;
    char *tokens = NULL, *tok = NULL;

    tokens = strdup(str);
    tok    = strtok((char *)tokens, ",");

    /* Parse levels */
    while (tok) {
        if (0 == strncasecmp(tok, "info", 4)) {
            level |= TJS_LOGLEVEL_INFO;
        } else if (0 == strncasecmp(tok, "error", 5)) {
            level |= TJS_LOGLEVEL_ERROR;
        } else if (0 == strncasecmp(tok, "duk", 3)) {
            level |= TJS_LOGLEVEL_DUK;
        } else if (0 == strncasecmp(tok, "debug", 5)) {
            level |= TJS_LOGLEVEL_DEBUG;
        }

        tok = strtok(NULL, ",");
    }

  free(tokens);

  return level;
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

    tjs_log(TJS_LOGLEVEL_DUK, func, line,
        "%s", duk_safe_to_string(ctx, -1));

    duk_pop(ctx);
}

/**
 * Terminate app
 **/

void tjs_exit() {
    duk_destroy_heap(touch.ctx);

    [NSApp terminate: NULL];
}

/******************************
 *          Update            *
 ******************************/

/**
 * Create view of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 * @param[in] .   idx    Element index
 **/

static void tjs_embed_create(TjsEmbed *embed, int idx) {
    /* Sanity check */
    if (0 < (embed->flags & TJS_FLAG_TYPE_EMBED) &&
        0 == (embed->flags & TJS_FLAG_STATE_CREATED) && NULL != embed->userdata)
    {
        /* Get delegate as target */
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];

        /* Handle type */
        if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_LABEL)) { ///< TjsLabel
            embed->view = [NSTextField labelWithString:
                [NSString stringWithUTF8String: ((TjsWidget *)embed->userdata)->value.asChar]];

            [((NSTextField *)embed->view) setTag: idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_BUTTON)) { ///< TjsButton
            embed->view = [NSButton buttonWithTitle:
                [NSString stringWithUTF8String: ((TjsWidget *)embed->userdata)->value.asChar]
                target: delegate action: @selector(button:)];

            [((NSButton *)embed->view) setTag: idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SLIDER)) { ///< TjsSlider
            embed->view = [NSSlider sliderWithValue: ((TjsWidget *)embed->userdata)->value.asInt
                minValue: 0 maxValue: 100 target: delegate action: @selector(slider:)];

            [((NSSlider *)embed->view) setTag: idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SCRUBBER)) {
            embed->view = [[NSScrollView alloc] initWithFrame: CGRectMake(0, 0, 400, 30)];
        }

        /* Mark as ready and update it */
        embed->flags |= TJS_FLAG_STATE_CREATED;
    }
}

/**
 * Update embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

static void tjs_embed_update(TjsEmbed *embed) {
    if (0 < (embed->flags & TJS_FLAG_TYPE_EMBED)) {
        tjs_embed_color(embed);
        tjs_embed_value(embed);
    }
}

/**
 * Configure view of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

 static void tjs_embed_configure(TjsEmbed *embed) {
    /* Sanity check */
    if (0 < (embed->flags & TJS_FLAG_TYPE_EMBED) &&
        0 == (embed->flags & TJS_FLAG_STATE_CONFIGURED) && NULL != embed->userdata)
    {
        /* Handle type */
        if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SCRUBBER)) {
            TjsScrubber *scrubber = (TjsScrubber *)(embed->userdata);

            NSMutableDictionary *constraintViews = [NSMutableDictionary dictionary];
            NSView *docView = [[NSView alloc] initWithFrame: NSZeroRect];
            NSSize size = NSMakeSize(8, 30);

            /* Build format and collect children */
            NSString *layoutFormat = @"H:|-8-";

            for (int i = 0; i < [touch.embedded count]; i++) {
                TjsEmbed *childEmbed = [[touch.embedded objectAtIndex: i] pointerValue];

                if (NULL != childEmbed && childEmbed->parent == embed->userdata) {
                    [childEmbed->view setTranslatesAutoresizingMaskIntoConstraints: NO];
                    [docView addSubview: childEmbed->view];

                    /* Append constraint */
                    NSString *identifier = [NSString stringWithFormat: @"widget%d", i];

                    layoutFormat = [layoutFormat stringByAppendingString:
                        [NSString stringWithFormat: @"[%@]-8-", identifier]];

                    [constraintViews setObject: childEmbed->view forKey: identifier];

                    size.width += 8 + childEmbed->view.intrinsicContentSize.width + 8;

                    tjs_embed_update(childEmbed);
                }
            }

            layoutFormat = [layoutFormat stringByAppendingString: [NSString stringWithFormat:@"|"]];

            /* Add layout constraint */
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat: layoutFormat
                options: NSLayoutFormatAlignAllCenterY metrics: nil views: constraintViews];

            [docView setFrame: NSMakeRect(0, 0, size.width, size.height)];
            [docView addConstraints: constraints];

            ((NSScrollView *)embed->view).documentView = docView;
        }

        /* Mark as configured */
        embed->flags |= TJS_FLAG_STATE_CONFIGURED;
    }
 }

/**
 * Update color of touch item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

static void tjs_embed_color(TjsEmbed *embed) {
    /* Sanity checks */
    if (0 < (embed->flags & TJS_FLAG_TYPE_EMBED) && NULL != embed->userdata &&
        0 < (embed->userdata->flags & TJS_FLAGS_COLORS))
    {
        TjsWidget *widget = (TjsWidget *)(embed->userdata);
        TjsColor *col = NULL;

        /* Selct fg or bg */
        if (0 < (widget->flags & TJS_FLAG_STATE_COLOR_FG)) {
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
        if (0 < (widget->flags & TJS_FLAG_STATE_COLOR_FG)) {
            if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) {
                [((NSTextView *)(embed->view)) setTextColor: parsedCol];
            }
        } else {
            if (0 < (widget->flags & TJS_FLAG_TYPE_BUTTON)) {
                [((NSButton *)(embed->view)) setBezelColor: parsedCol];
            } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
                [((NSSlider *)(embed->view)) setTrackFillColor: parsedCol];
                [((NSSlider *)(embed->view)) setNeedsDisplay];
            }
        }

        /* Remove flags if ready */
        if (0 < (embed->flags & TJS_FLAG_STATE_CREATED)) {
            widget->flags &= ~TJS_FLAGS_COLORS;
        }
    }
}

/**
 * Update value of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

static void tjs_embed_value(TjsEmbed *embed) {
    /* Sanity check */
    if (0 < (embed->flags & TJS_FLAG_TYPE_EMBED) && NULL != embed->userdata &&
        0 < (embed->userdata->flags & TJS_FLAG_STATE_VALUE))
    {
        TjsWidget *widget = (TjsWidget *)(embed->userdata);

        /* Handle widget types */
        if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) {
            [((NSTextField *)(embed->view)) setStringValue:
                [NSString stringWithUTF8String: widget->value.asChar]];
        } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            [((NSSlider *)(embed->view)) setDoubleValue: widget->value.asInt];
        }

        /* Remove flags if ready */
        if (0 < (embed->flags & TJS_FLAG_STATE_CREATED)) {
            widget->flags &= ~TJS_FLAG_STATE_VALUE;
        }
    }
}

/**
 * Update touchbar item based on state and userdata
 *
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_update(TjsUserdata *userdata) {
    if (NULL != userdata && 0 < (userdata->flags & TJS_FLAGS_ATTACHABLE)) {
        TJS_LOG_OBJ(userdata);

        /* Find embed item */
        TjsEmbed *embed = tjs_find(userdata, NULL);

        if (NULL != embed) {
            tjs_embed_update(embed);
        }
    }
}

/******************************
 *           Embed            *
 ******************************/

/**
 * Find embed item based on userdata
 *
 * @param[in]   userdata  A #TjsUserdata
 * @param[out]  idx       Idx of found item; otherwise -1
 *
 * @return Either found #TjsEmbed; otherwise NULL
 **/

static TjsEmbed *tjs_find(TjsUserdata *userdata, int *idx) {
    for (int i = 0; i < [touch.embedded count]; i++) {
        TjsEmbed *embed = [[touch.embedded objectAtIndex: i] pointerValue];

        if (embed->userdata == userdata) {
            /* Copy idx */
            if (NULL != idx) {
                *idx = i;
            }

            return embed;
        }
    }

    /* Mark as not found */
    if (NULL != idx) {
        *idx = -1;
    }

    return NULL;
}

/**
 * Attach embed item to touchbar
 *
 * @param[inout]  ctx       A #duk_context
 * @param[inout]  userdata  A #TjsUserdata
 * @param[inout]  parent    A #TjsUserdata
 **/

void tjs_attach(duk_context *ctx, TjsUserdata *userdata, TjsUserdata *parent) {
    if (NULL != userdata) {
        TJS_LOG_OBJ(userdata);

        /* Create new embed */
        TjsEmbed *embed = (TjsEmbed *)calloc(1, sizeof(TjsEmbed));

        embed->flags = TJS_FLAG_TYPE_EMBED;
        embed->userdata = userdata;
        embed->parent = parent;
        embed->identifier = [NSString stringWithFormat:
            @"org.subforge.embed%lu", [touch.embedded count]];

        tjs_embed_create(embed, [touch.embedded count]);

        /* Store in array */
        [touch.embedded addObject: [NSValue value: &embed
            withObjCType: @encode(TjsEmbed *)]];

        /* Store global in context */
        duk_put_global_string(touch.ctx, [embed->identifier UTF8String]);
    }
}

/**
 * Detach embed item based on userdata
 *
 * @param[inout]  ctx       A #duk_context
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_detach(duk_context *ctx, TjsUserdata *userdata) {
    if (NULL != userdata) {
        int idx = 0;

        TJS_LOG_OBJ(userdata);

        /* Find embed item */
        TjsEmbed *embed = tjs_find(userdata, &idx);

        if (NULL != embed) {
            /* Overwrite global string with null aka remove it */
            duk_push_null(touch.ctx);
            duk_put_global_string(touch.ctx, [embed->identifier UTF8String]);

            free(embed);
        }
    }
}

/******************************
 *             I/O            *
 ******************************/

/**
 * Read and eval file
 *
 * @param[in]  source  Name of file to load
 **/

static void tjs_eval_file(char *source) {
    TJS_LOG_INFO("Loading file %s", source);

    /* Load file */
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:
        [NSString stringWithUTF8String: source]];

    if (NULL == file) {
        TJS_LOG_ERROR("Failed to open file file %s", source);

        return;
    }

    /* Read and convert data */
    NSData *buffer = [file readDataToEndOfFile];
    NSString *data = [[NSString alloc] initWithData: buffer
        encoding: NSUTF8StringEncoding];

    [file closeFile];

    if (NULL != data) {
        /* Just eval the content */
        TJS_LOG_INFO("Eval'ing file %s", source);

        duk_eval_string_noresult(touch.ctx, (char *)[data UTF8String]);
    }
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

    touch.embedded = [NSMutableArray arrayWithCapacity: 0];
    touch.loglevel = (TJS_LOGLEVEL_INFO|TJS_LOGLEVEL_DUK|TJS_LOGLEVEL_ERROR);

    /* Create duk context */
    touch.ctx = duk_create_heap(NULL, NULL, NULL, NULL, tjs_fatal);

    /* Register functions */
    tjs_global_init(touch.ctx);
    tjs_command_init(touch.ctx);
    tjs_win_init(touch.ctx);
    tjs_wm_init(touch.ctx);
    tjs_scrubber_init(touch.ctx);
    tjs_button_init(touch.ctx);
    tjs_label_init(touch.ctx);
    tjs_slider_init(touch.ctx);

    /* Commandline arguments */
    int c, fileOptId = -1;

    while (-1 != (c = getopt(argc, argv, "df:hl:v"))) {
        switch (c) {
            case 'd': touch.loglevel |= TJS_LOGLEVEL_DEBUG; break;
            case 'f': fileOptId = optind - 1;               break;
            case 'h': tjs_usage();                          return 0;
            case 'l': touch.loglevel = tjs_level(optarg);   break;
            case 'v': tjs_version();                        return 0;
        }
    }

    /* Eval file after debug/loglevel is set */
    if (-1 != fileOptId) {
        tjs_eval_file(argv[fileOptId]);
    }

    /* Create and run application */
    AppDelegate *del = [[AppDelegate alloc] init];

    [NSApp setDelegate: del];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp run];

    /* Tidy up */
    tjs_exit();

    return 0;
}