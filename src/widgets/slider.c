/**
 * @package TouchJS
 *
 * @file Slider functions
 * @copyright (c) 2019-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "widget.h"

#include "../common/callback.h"
#include "../common/userdata.h"

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_slider_ctor(duk_context *ctx) {
        /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_SLIDER, sizeof(TjsWidget));

    if (NULL == widget) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    widget->value.asInt = duk_require_int(ctx, -1);
    duk_pop(ctx);

    tjs_userdata_init(ctx, (TjsUserdata *)widget);

    TJS_LOG_DEBUG("flags=%d", widget->flags);

    return 0;
}

/**
 * Native bind prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_slider_prototype_bind(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);

    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SLIDER);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        /* Store slide callback */
        duk_push_this(ctx);
        duk_swap_top(ctx, -2);
        duk_put_prop_string(ctx, -2, TJS_SYM_SLIDE_CB);
        duk_pop(ctx);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Native getPercent prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_slider_prototype_getpercent(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SLIDER);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d, percent=%d",
            widget->flags, widget->value.asInt);

        duk_push_int(ctx, widget->value.asInt);

        return 1;
    }

    return 0;
}

/**
 * Native setPercent prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_slider_prototype_setpercent(duk_context *ctx) {
    int percent = duk_require_int(ctx, -1);

    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SLIDER);

    if (NULL != widget) {
        widget->flags |= TJS_FLAG_STATE_VALUE;
        widget->value.asInt = percent;

        TJS_LOG_DEBUG("flags=%d, percent=%d",
            widget->flags, widget->value.asInt);
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

static duk_ret_t tjs_slider_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_SLIDER);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        duk_push_sprintf(ctx, "flags=%d, value=%d",
            widget->flags, widget->value.asInt);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsSlider
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_slider_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_slider_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_slider_prototype_bind, 1);
    duk_put_prop_string(ctx, -2, "bind");

    duk_push_c_function(ctx, tjs_slider_prototype_getpercent, 0);
    duk_put_prop_string(ctx, -2, "getPercent");

    duk_push_c_function(ctx, tjs_slider_prototype_setpercent, 1);
    duk_put_prop_string(ctx, -2, "setPercent");

    duk_push_c_function(ctx, tjs_widget_prototype_setbgcolor, 3);
    duk_put_prop_string(ctx, -2, "setBgColor");

    duk_push_c_function(ctx, tjs_slider_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsSlider");
}