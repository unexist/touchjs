/**
 * @package TouchJS
 *
 * @file Slider functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"

/**
 * Native slider constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

duk_ret_t tjs_slider_ctor(duk_context *ctx) {
    return tjs_control_ctor(ctx, TJS_FLAG_TYPE_LABEL);
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
    duk_push_c_function(ctx, tjs_control_helper_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsSlider");
}