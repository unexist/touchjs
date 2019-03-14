/**
 * @package TouchJS
 *
 * @file Global functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "touchjs.h"

/**
 * Native print method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_print(duk_context *ctx) {
    /* Join strings on stack */
	duk_push_string(ctx, " ");
	duk_insert(ctx, 0);
	duk_join(ctx, duk_get_top(ctx) - 1);

    TJS_LOG_DUK("%s", duk_safe_to_string(ctx, -1));

    return 0;
}

/**
 * Native rgb method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_rgb(duk_context *ctx) {
    /* Sanitize value */
    const char *hexcode = duk_require_string(ctx, -1);
    duk_pop(ctx);

    if ('#' != hexcode[0]) {
        return duk_error(ctx, DUK_ERR_TYPE_ERROR,
            "Invalid argument value: '%s'", hexcode);
    }

    /* Convert string to hex */
    unsigned int color = strtol(++hexcode, NULL, 16);

    /* Mask color values */
    unsigned char red = (unsigned char)(color >> 16);
    unsigned char green = (unsigned char)(color >> 8);
    unsigned char blue = (unsigned char)(color);

    /* Push array */
    duk_idx_t idx = duk_push_array(ctx);

    duk_push_int(ctx, red);
    duk_put_prop_index(ctx, idx, 0);
    duk_push_int(ctx, green);
    duk_put_prop_index(ctx, idx, 1);
    duk_push_int(ctx, blue);
    duk_put_prop_index(ctx, idx, 2);

    return 1;
}

/**
 * Native attach method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_attach(duk_context *ctx) {
    /* Sanity check */
    duk_require_object(ctx, -1);
    duk_dup_top(ctx); ///< Dup to prevent next call removing it from stack

    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_from(ctx, TJS_FLAGS_ATTACHABLE);

    if (NULL != userdata) {
        tjs_attach(ctx, userdata, NULL);
    }

    return 0;
}

/**
 * Native detach method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_detach(duk_context *ctx) {
    /* Sanity check */
    duk_require_object(ctx, -1);
    duk_dup_top(ctx); ///< Dup to prevent next call removing it from stack

    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_from(ctx, TJS_FLAGS_ATTACHABLE);

    if (NULL != userdata) {
        tjs_detach(ctx, userdata);
    }

    return 0;
}

/**
 * Native quit method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_global_quit(duk_context *ctx) {
    TJS_LOG_INFO("Exiting");

    tjs_exit();

    return 0;
}

/**
 * Init methods for global
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_global_init(duk_context *ctx) {
    /* Register methods */
    duk_push_c_function(ctx, tjs_global_print, DUK_VARARGS);
    duk_put_global_string(ctx, "tjs_print");

    duk_push_c_function(ctx, tjs_global_rgb, 1);
    duk_put_global_string(ctx, "tjs_rgb");

    duk_push_c_function(ctx, tjs_global_attach, 1);
    duk_put_global_string(ctx, "tjs_attach");

    duk_push_c_function(ctx, tjs_global_detach, 1);
    duk_put_global_string(ctx, "tjs_rgb");

    duk_push_c_function(ctx, tjs_global_quit, 0);
    duk_put_global_string(ctx, "tjs_quit");
}