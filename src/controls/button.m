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

#import "../touchjs.h"

 /**
  * Native button click prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

void tjs_button_helper_click(duk_context *ctx) {
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_CLICK_CB);

    /* Call if callable */
    if (duk_is_callable(ctx, -1)) {
        duk_swap_top(ctx, -2);
        duk_pcall_method(ctx, 0);
        duk_pop(ctx); ///< Ignore result
    }
}

 /**
 * Native button constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

duk_ret_t tjs_button_ctor(duk_context *ctx) {
    return tjs_control_ctor(ctx, TJS_FLAG_TYPE_BUTTON);
}

/**
 * Native button bind prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

duk_ret_t tjs_button_prototype_bind(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);

    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);

        /* Store click callback */
        duk_push_this(ctx);
        duk_swap_top(ctx, -2);
        duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_CLICK_CB);
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

duk_ret_t tjs_button_prototype_click(duk_context *ctx) {
    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);

        /* Call click callback */
        duk_push_this(ctx);
        tjs_button_helper_click(ctx);
  }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native button print prototype method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_button_prototype_print(duk_context *ctx) {
    tjs_control_helper_tostring(ctx);

    TJS_LOG("%s", duk_safe_to_string(ctx, -1));

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
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

    duk_push_c_function(ctx, tjs_button_prototype_print, 0);
    duk_put_prop_string(ctx, -2, "print");

    duk_push_c_function(ctx, tjs_control_prototype_setbgcolor, 3);
    duk_put_prop_string(ctx, -2, "setBgColor");

    duk_push_c_function(ctx, tjs_control_helper_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsButton");
}