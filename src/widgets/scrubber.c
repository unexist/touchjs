/**
 * @package TouchJS
 *
 * @file Scrubber functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "../touchbar.h"
#include "widget.h"

#include "../common/userdata.h"

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_scrubber_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_SCRUBBER, sizeof(TjsWidget));

    if (NULL == widget) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    tjs_userdata_init(ctx, (TjsUserdata *)widget);

    TJS_LOG_OBJ(widget);

    return 0;
}

/**
 * Native attach method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_scrubber_prototype_attach(duk_context *ctx) {
    /* Sanity check */
    duk_require_object(ctx, -1);

    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_from(ctx, TJS_FLAGS_WIDGETS);
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SCRUBBER);

    if (NULL != widget) {
        TJS_LOG_OBJ(widget);

        tjs_touchbar_attach(ctx, userdata, (TjsUserdata *)widget);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Native detach method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_scrubber_prototype_detach(duk_context *ctx) {
    /* Sanity check */
    duk_require_object(ctx, -1);

    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_from(ctx, TJS_FLAGS_WIDGETS);
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SCRUBBER);

    if (NULL != widget) {
        TJS_LOG_OBJ(widget);

        tjs_touchbar_detach(ctx, userdata);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Native toString prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_scrubber_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SCRUBBER);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        duk_push_sprintf(ctx, "flags=%d", widget->flags);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsScrubber
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_scrubber_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_scrubber_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_scrubber_prototype_attach, 1);
    duk_put_prop_string(ctx, -2, "attach");

    duk_push_c_function(ctx, tjs_scrubber_prototype_detach, 1);
    duk_put_prop_string(ctx, -2, "detach");

    duk_push_c_function(ctx, tjs_scrubber_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsScrubber");
}