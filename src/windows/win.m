/**
 * @package TouchJS
 *
 * @file Win functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"
#import <Cocoa/Cocoa.h>

/* Types */
typedef struct tjs_win_t {
    int flags;

    /* Obj-c */
} TjsWin;

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_WIN, sizeof(TjsWin));

    if (NULL == win) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    duk_pop(ctx);

    tjs_super_init(ctx, (TjsUserdata *)win);

    TJS_LOG_OBJ(win);

    return 0;
}

/**
 * Native label getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        duk_push_sprintf(ctx, "flags=%d", win->flags);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsCommand
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_win_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_win_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_win_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsWin");
}