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
#include "duktape/duktape.h"

/* Symbols */
#define TJS_SYM_CLICK_CB "\xff" "__click_cb"
#define TJS_SYM_SLIDE_CB "\xff" "__slide_cb"
#define TJS_SYM_USERDATA "\xff" "__userdata"

/* Flags */
#define TJS_FLAG_TYPE_EMBED (1L << 0)
#define TJS_FLAG_TYPE_COMMAND (1L << 1)
#define TJS_FLAG_TYPE_LABEL  (1L << 2)
#define TJS_FLAG_TYPE_BUTTON (1L << 3)
#define TJS_FLAG_TYPE_SLIDER  (1L << 4)
#define TJS_FLAG_TYPE_SCRUBBER  (1L << 5)

#define TJS_FLAG_UPDATE_COLOR_FG (1L << 10)
#define TJS_FLAG_UPDATE_COLOR_BG (1L << 11)
#define TJS_FLAG_UPDATE_VALUE (1L << 12)

#define TJS_FLAG_STANDALONE (1L << 20)

#define TJS_FLAG_QUIT (1L << 29)
#define TJS_FLAG_READY (1L << 30)

/* Combined */
#define TJS_FLAGS_WIDGETS \
    (TJS_FLAG_TYPE_LABEL|TJS_FLAG_TYPE_BUTTON|TJS_FLAG_TYPE_SLIDER)
#define TJS_FLAGS_ATTACHABLE \
    (TJS_FLAGS_WIDGETS|TJS_FLAG_TYPE_SCRUBBER)
#define TJS_FLAGS_COLORS \
    (TJS_FLAG_UPDATE_COLOR_FG|TJS_FLAG_UPDATE_COLOR_BG)
#define TJS_FLAGS_UPDATES \
    (TJS_FLAG_COLORS|TJS_FLAG_UPDATE_VALUE)

/* Loglevel */
#define TJS_LOGLEVEL_INFO (1L << 0)
#define TJS_LOGLEVEL_DEBUG (1L << 1)
#define TJS_LOGLEVEL_ERROR (1L << 2)
#define TJS_LOGLEVEL_DUK (1L << 3)

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

/* Types */
typedef struct tjs_color_t {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} TjsColor;

typedef union tjs_value_t {
    char *asChar;
    int asInt;
    double asDouble;
} TjsValue;

typedef struct tjs_userdata_t {
    int flags;
} TjsUserdata;

typedef struct tjs_scrubber_t
{
    int flags;
    int nuserdata;
    TjsUserdata **userdata;
} TjsScrubber;

typedef struct tjs_widget_t
{
    int flags;

    struct{
        struct tjs_color_t fg;
        struct tjs_color_t bg;
    } colors;

    union tjs_value_t value;
} TjsWidget;

/* Globals */
duk_context *_ctx;

/* touchjs.m */
void tjs_log(int loglevel, const char *func, int line, const char *fmt, ...);
void tjs_fatal(void *userdata, const char *msg);
void tjs_dump_stack(const char *func, int line, duk_context *ctx);
void tjs_exit(void);
void tjs_attach(duk_context *ctx, TjsUserdata *userdata);
void tjs_detach(duk_context *ctx, TjsUserdata *userdata);

/* Update.m */
void tjs_update(TjsUserdata *userdata);

/* command.m */
void tjs_command_init(duk_context *ctx);

/* scrubber.m */
void tjs_scrubber_init(duk_context *ctx);

/* global.c */
void tjs_global_init(duk_context *ctx);

/* userdata.c */
TjsUserdata *tjs_userdata_new(duk_context *ctx, int flags, size_t datasize);
TjsUserdata *tjs_userdata_get(duk_context *ctx, int flag);
TjsUserdata *tjs_userdata_from(duk_context *ctx, int flag);
void tjs_userdata_free(TjsUserdata *userdata);

/* super.c */
void tjs_super_update(TjsUserdata *userdata);
//void tjs_super_callback_add(duk_context *ctx, const char *sym);
void tjs_super_callback_call(duk_context *ctx, const char *sym, int nargs);

duk_ret_t tjs_super_prototype_setfgcolor(duk_context *ctx);
duk_ret_t tjs_super_prototype_setbgcolor(duk_context *ctx);

void tjs_super_init(duk_context *ctx, TjsUserdata *userdata);

/* label.c */
void tjs_label_init(duk_context *ctx);

/* button.c */
void tjs_button_init(duk_context *ctx);

/* slider.m */
void tjs_slider_init(duk_context *ctx);

#endif /* TJS_TOUCHJS_H */