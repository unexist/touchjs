/**
 * @package TouchJS
 *
 * @file Context functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "userdata.h"

/**
 * Native userdata destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_userdata_dtor(duk_context *ctx) {
    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_get(ctx,
        TJS_FLAGS_WIDGETS);

    if (NULL != userdata) {
        TJS_LOG_OBJ(userdata);

        tjs_userdata_destroy(userdata);
    }

    return 0;
}

/**
 * Create new userdata
 *
 * @param[inout]  ctx       A #duk_context
 * @param[in]     flags     Context flags
 * @param[in]     datasize  Size of the userdata
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

 TjsUserdata *tjs_userdata_new(duk_context *ctx, int flags, size_t datasize) {
    /* Create new userdata */
    TjsUserdata *userdata = (TjsUserdata *)calloc(1, datasize);

    userdata->flags = flags;

    /* Store pointer ref */
    duk_push_this(ctx);
    duk_push_pointer(ctx, userdata);
    duk_put_prop_string(ctx, -2, TJS_SYM_USERDATA);
    duk_pop(ctx);

    TJS_LOG_OBJ(userdata);

    return userdata;
 }

/**
 * Get context from current duktape object
 *
 * @param[inout]  ctx   A #duk_context
 * @param[in]     flag  Flag to fetch
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

TjsUserdata *tjs_userdata_get(duk_context *ctx, int flag) {
    duk_push_this(ctx);

    return tjs_userdata_from(ctx, flag);
}

/**
 * Get context from duktape object
 *
 * @param[inout]  ctx   A #duk_context
 * @param[in]     flag  Flag to fetch
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

TjsUserdata *tjs_userdata_from(duk_context *ctx, int flag) {
    /* Get userdata and clear stack */
    duk_get_prop_string(ctx, -1, TJS_SYM_USERDATA);

    TjsUserdata *userdata = (TjsUserdata *)duk_get_pointer(ctx, -1);
    duk_pop(ctx);

    TJS_LOG_OBJ(userdata);

    return (0 < (userdata->flags & flag) ? userdata : NULL);
}

/**
 * Native userdata init
 *
 * @param[inout]  ctx      A #duk_context
 * @param[inout]  control  A #TjsUserdata
 **/

void tjs_userdata_init(duk_context *ctx, TjsUserdata *userdata) {
    /* Register destructor */
    duk_push_this(ctx);
    duk_push_c_function(ctx, tjs_userdata_dtor, 0);
    duk_set_finalizer(ctx, -2);
    duk_pop(ctx);

    if (NULL != userdata) {
        TJS_LOG_OBJ(userdata);
    }
}

/**
 * Destroy userdata
 *
 * @param[inout]  control  A #TjsUserdata
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

void tjs_userdata_destroy(TjsUserdata *userdata) {
    if (NULL != userdata) {
        free(userdata);
    }
}