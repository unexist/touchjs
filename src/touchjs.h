/**
 * @package TouchJS
 *
 * @file Main header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

/* Imports and includes */
#import <Cocoa/Cocoa.h>

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
#define TJS_FLAG_TYPE_SLIDER  (1L << 2)

#define TJS_FLAG_COLOR_FG (1L << 5)
#define TJS_FLAG_COLOR_BG (1L << 6)

/* Internal structs */
typedef struct tjs_color_t {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} TjsColor;

typedef struct tjs_control_t {
    int flags;
    int idx;
    char *title;

    char *callback;

    struct {
        struct tjs_color_t fg;
        struct tjs_color_t bg;
    } colors;

    union {
        char *asChar;
        double asDouble;
    } value;

    /* Obj-c */
    NSTouchBarItemIdentifier identifier;
    NSView *view;
} TjsControl;

/* Globals */
static const NSTouchBarItemIdentifier kGroupButton = @"org.subforge.group";
static const NSTouchBarItemIdentifier kQuit = @"org.subforge.quit";

NSTouchBar *_groupTouchBar;
NSMutableArray *_touchbarControls;
duk_context *_ctx;

/* Forward declarations */
extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

void tjs_dump_stack(const char *func, int line, duk_context *ctx);
void tjs_control_helper_update(TjsControl *control);
void tjs_button_helper_click(duk_context *ctx);

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

/* touchjs.m */
void tjs_log(const char *func, int line, const char *fmt, ...);
void tjs_fatal(void *userdata, const char *msg);
void tjs_dump_stack(const char *func, int line, duk_context *ctx);

/* global.m */
duk_ret_t tjs_global_print(duk_context *ctx);
duk_ret_t tjs_global_rgb(duk_context *ctx);
duk_ret_t tjs_global_quit(duk_context *ctx);
void tjs_global_init(duk_context *ctx);

/* control.m */
void tjs_control_helper_update(TjsControl *control);
duk_ret_t tjs_control_helper_tostring(duk_context *ctx);
duk_ret_t tjs_control_helper_setcolor(duk_context *ctx, int flag);
duk_ret_t tjs_control_prototype_setfgcolor(duk_context *ctx);
duk_ret_t tjs_control_prototype_setbgcolor(duk_context *ctx);
duk_ret_t tjs_control_dtor(duk_context *ctx);
duk_ret_t tjs_control_ctor(duk_context *ctx, int flags);

/* userdata.m */
TjsControl *tjs_control_userdata_new(duk_context *ctx, int flags, const char *title);
TjsControl *tjs_control_userdata_get(duk_context *ctx);

/* button.m */
void tjs_button_helper_click(duk_context *ctx);
duk_ret_t tjs_button_ctor(duk_context *ctx);
duk_ret_t tjs_button_prototype_bind(duk_context *ctx);
duk_ret_t tjs_button_prototype_click(duk_context *ctx);
duk_ret_t tjs_button_prototype_print(duk_context *ctx);
void tjs_button_init(duk_context *ctx);

/* label.m */
duk_ret_t tjs_label_ctor(duk_context *ctx);
void tjs_label_init(duk_context *ctx);

/* slider.m */
duk_ret_t tjs_slider_ctor(duk_context *ctx);
void tjs_slider_init(duk_context *ctx);