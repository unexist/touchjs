/**
 * @package TouchJS
 *
 * @file Label functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "widget.h"

#include "../common/userdata.h"

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_label_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_LABEL, sizeof(TjsWidget));

    if (NULL == widget) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    widget->value.asChar = strdup((char *)duk_require_string(ctx, -1));
    duk_pop(ctx);

    tjs_userdata_init(ctx, (TjsUserdata *)widget);

    TJS_LOG_OBJ(widget);

    return 0;
}

/**
 * Native getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_label_prototype_getvalue(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_LABEL);

    if (NULL != widget) {
        TJS_LOG_DEBUG("obj=%p, flags=%d, value=%s",
            widget, widget->flags, widget->value.asChar);

        duk_push_string(ctx, widget->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Native toString prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_label_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWidget *widget = (TjsWidget *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_LABEL);

    if (NULL != widget) {
        TJS_LOG_OBJ(widget);

        duk_push_sprintf(ctx, "flags=%d, value=%s",
            widget->flags, widget->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsLabel
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_label_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_label_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_label_prototype_getvalue, 0);
    duk_put_prop_string(ctx, -2, "getValue");

    duk_push_c_function(ctx, tjs_label_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_push_c_function(ctx, tjs_widget_prototype_setfgcolor, 3);
    duk_put_prop_string(ctx, -2, "setFgColor");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsLabel");
}