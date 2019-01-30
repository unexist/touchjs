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

#include "touchjs.h"

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

    TJS_LOG_DEBUG("flags=%d", userdata->flags);

    return userdata;
 }

/**
 * Get context from duktape object
 *
 * @param[inout]  ctx  A #duk_context
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

TjsUserdata *tjs_userdata_get(duk_context *ctx) {
    /* Get userdata and clear stack */
    duk_push_this(ctx);
    duk_get_prop_string(ctx, -1, TJS_SYM_USERDATA);

    TjsUserdata *userdata = (TjsUserdata *)duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);

    TJS_LOG_DEBUG("flags=%d", userdata->flags);

    return userdata;
}

/**
 * Free userdata
 *
 * @param[inout]  control  A #TjsUserdata
 *
 * @return Either #TjsUserdata on success; otherwise #null
 **/

void tjs_userdata_free(TjsUserdata *userdata) {
    if (NULL != userdata) {
        free(userdata);
    }
}