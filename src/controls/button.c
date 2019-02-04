/**
 * @package TouchJS
 *
 * @file Button functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

 /**
 * Native button constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_BUTTON, sizeof(TjsWidget));

    if (NULL == widget) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    widget->value.asChar = strdup((char *)duk_require_string(ctx, -1));
    duk_pop(ctx);

    tjs_super_init(ctx, (TjsUserdata *)widget);

    TJS_LOG_DEBUG("flags=%d", widget->flags);

    return 0;
}

/**
 * Native button bind prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_prototype_bind(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);

    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_BUTTON);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        /* Store click callback */
        duk_push_this(ctx);
        duk_swap_top(ctx, -2);
        duk_put_prop_string(ctx, -2, TJS_SYM_CLICK_CB);
        duk_pop(ctx);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
  * Native button click prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

static duk_ret_t tjs_button_prototype_click(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_BUTTON);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        /* Call click callback */
        duk_push_this(ctx);
        tjs_super_callback_call(ctx, TJS_SYM_CLICK_CB, 0);
  }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

/**
 * Native button getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_prototype_getvalue(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_BUTTON);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d, value=%s",
            widget->flags, widget->value.asChar);

        duk_push_string(ctx, widget->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Native button getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_button_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_BUTTON);

    if (NULL != widget) {
        TJS_LOG_DEBUG("flags=%d", widget->flags);

        duk_push_sprintf(ctx, "flags=%d, value=%s",
            widget->flags, widget->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #Tjsbutton
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_button_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_button_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_button_prototype_bind, 1);
    duk_put_prop_string(ctx, -2, "bind");

    duk_push_c_function(ctx, tjs_button_prototype_click, 0);
    duk_put_prop_string(ctx, -2, "click");

    duk_push_c_function(ctx, tjs_button_prototype_getvalue, 0);
    duk_put_prop_string(ctx, -2, "getValue");

    duk_push_c_function(ctx, tjs_button_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_push_c_function(ctx, tjs_super_prototype_setbgcolor, 3);
    duk_put_prop_string(ctx, -2, "setBgColor");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsButton");
}