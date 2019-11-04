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

#ifndef TJS_TOUCHJS_H
#define TJS_TOUCHJS_H 1

/* Includes */
#include <stdio.h>

#include "libs/duktape/duktape.h"

/* Package */
#define PKG_NAME "TouchJS"
#define PKG_VERSION "0.0"
#define PKG_BUGREPORT "unexist@subforge.org"

/* Flags */
#define TJS_FLAG_TYPE_EMBED (1L << 0)
#define TJS_FLAG_TYPE_COMMAND (1L << 1)

#define TJS_FLAG_TYPE_WM (1L << 2)
#define TJS_FLAG_TYPE_SCREEN (1L << 3)
#define TJS_FLAG_TYPE_WIN (1L << 4)

#define TJS_FLAG_TYPE_LABEL  (1L << 10)
#define TJS_FLAG_TYPE_BUTTON (1L << 11)
#define TJS_FLAG_TYPE_SLIDER  (1L << 12)
#define TJS_FLAG_TYPE_SCRUBBER  (1L << 13)

#define TJS_FLAG_STATE_COLOR_FG (1L << 26)
#define TJS_FLAG_STATE_COLOR_BG (1L << 27)
#define TJS_FLAG_STATE_VALUE (1L << 28)
#define TJS_FLAG_STATE_CONFIGURED (1L << 29)
#define TJS_FLAG_STATE_CREATED (1L << 30)

/* Combined */
#define TJS_FLAGS_WIDGETS \
    (TJS_FLAG_TYPE_LABEL|TJS_FLAG_TYPE_BUTTON|TJS_FLAG_TYPE_SLIDER)
#define TJS_FLAGS_ATTACHABLE \
    (TJS_FLAGS_WIDGETS|TJS_FLAG_TYPE_SCRUBBER)
#define TJS_FLAGS_COLORS \
    (TJS_FLAG_STATE_COLOR_FG|TJS_FLAG_STATE_COLOR_BG)
#define TJS_FLAGS_UPDATES \
    (TJS_FLAG_COLORS|TJS_FLAG_STATE_VALUE)

/* Loglevel */
#define TJS_LOGLEVEL_INFO (1L << 0)
#define TJS_LOGLEVEL_DEBUG (1L << 1)
#define TJS_LOGLEVEL_ERROR (1L << 2)
#define TJS_LOGLEVEL_DUK (1L << 3)
#define TJS_LOGLEVEL_OBSERVER (1L << 4)
#define TJS_LOGLEVEL_EVENT (1L << 5)

/* Macros */
#define TJS_DSTACK(CTX) \
    tjs_dump_stack(__FUNCTION__, __LINE__, CTX);
#define TJS_LOG_INFO(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_INFO, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_DEBUG(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_DEBUG, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_ERROR(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_ERROR, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_DUK(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_DUK, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_OBSERVER(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_OBSERVER, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_EVENT(FMT, ...) \
    tjs_log(TJS_LOGLEVEL_EVENT, __FUNCTION__, __LINE__, FMT, ##__VA_ARGS__);
#define TJS_LOG_OBJ(OBJ) \
    tjs_log(TJS_LOGLEVEL_DEBUG, __FUNCTION__, __LINE__, "obj=%p, flags=%d", OBJ, OBJ->flags);

/* Types */
typedef struct tjs_touch_t {
    int flags;
    int loglevel;

    duk_context *ctx;
} TjsTouch;

/* Globals */
TjsTouch touch;

/* touchjs.m */
void tjs_log(int level, const char *func, int line, const char *fmt, ...);
void tjs_fatal(void *userdata, const char *msg);
void tjs_dump_stack(const char *func, int line, duk_context *ctx);
void tjs_exit(void);

/******************************
 *          Objects           *
 ******************************/

/* global.c */
void tjs_global_init(duk_context *ctx);

/* command.m */
void tjs_command_init(duk_context *ctx);

/******************************
 *             WM             *
 ******************************/

/* wm.m */
void tjs_wm_init(duk_context *ctx);

/* screen.m */
void tjs_screen_init(duk_context *ctx);

/* win.m */
void tjs_win_init(duk_context *ctx);

/******************************
 *          Widgets           *
 ******************************/

/* button.c */
void tjs_button_init(duk_context *ctx);

/* label.c */
void tjs_label_init(duk_context *ctx);

/* slider.m */
void tjs_slider_init(duk_context *ctx);

/* scrubber.m */
void tjs_scrubber_init(duk_context *ctx);

#endif /* TJS_TOUCHJS_H */