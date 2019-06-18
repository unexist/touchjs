/**
 * @package TouchJS
 *
 * @file Screen functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "screen.h"

#include "../common/userdata.h"

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_screen_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsScreen *screen = (TjsScreen *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_SCREEN, sizeof(TjsScreen));

    if (NULL == screen) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    duk_pop(ctx);

    tjs_userdata_init(ctx, (TjsUserdata *)screen);

    TJS_LOG_OBJ(screen);

    return 0;
}

/**
 * Native win setFrame prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_screen_prototype_getframe(duk_context *ctx) {
    /* Get userdata */
    TjsScreen *screen = (TjsScreen *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SCREEN);

    if (NULL != screen) {
        TJS_LOG_OBJ(screen);

        tjs_frame_to_array(&(screen->frame), ctx);

        return 1;
    }

    return 0;
}

/**
 * Native label getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_screen_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsScreen *screen = (TjsScreen *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SCREEN);

    if (NULL != screen) {
        TJS_LOG_OBJ(screen);

        duk_push_sprintf(ctx, "flags=%d", screen->flags);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsScreen
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_screen_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_screen_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */

    /* Geometry */
    duk_push_c_function(ctx, tjs_screen_prototype_getframe, 0);
    duk_put_prop_string(ctx, -2, "getFrame");

    duk_push_c_function(ctx, tjs_screen_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsScreen");
}