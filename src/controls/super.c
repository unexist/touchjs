/**
 * @package TouchJS
 *
 * @file Control functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

 /**
  * Helper to call given callback
  *
  * @param[inout]  ctx    A #duk_context
  * @param[in]     sym    Symbol to call if found
  * @param[in]     nargs  Number of arguments for callback
  **/

void tjs_super_callback_call(duk_context *ctx, const char *sym, int nargs) {
    duk_get_prop_string(ctx, -1 - nargs, sym); ///< Update index based on number of arguments

    /* Call if callable */
    if (duk_is_callable(ctx, -1)) {
        duk_swap_top(ctx, -(2 + nargs)); ///< Move based on number of arguments
        duk_pcall_method(ctx, nargs);
        duk_pop(ctx); ///< Ignore result
    }
}

 /**
  * Helper to set the control color
  *
  * @param[inout]  ctx   A #duk_context
  * @param[in]     flag  Color flag
  **/

static duk_ret_t tjs_super_setcolor(duk_context *ctx, int flag) {
    /* Fetch colors from stack */
    int blue = duk_require_int(ctx, -1);
    int green = duk_require_int(ctx, -2);
    int red = duk_require_int(ctx, -3);

    /* Get context */
    TjsUserdata *userdata = tjs_userdata_get(ctx);

    /* Get userdata */
    if (NULL != userdata) {
        TjsWidget *widget = (TjsWidget *)userdata;

        TJS_LOG_DEBUG("flags=%d, red=%d, green=%d, blue=%d",
           widget->flags, red, green, blue);

        /* Store color in case control isn't visible */
        TjsColor *color = NULL;
        widget->flags |= flag;

        if (TJS_FLAG_UPDATE_COLOR_FG == flag) {
            color = &(widget->colors.fg);
        } else {
            color = &(widget->colors.bg);
        }

        color->red = red;
        color->green = green;
        color->blue = blue;

        tjs_touch_update(userdata);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native super string prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_super_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_get(ctx);

    if (NULL != userdata) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);

        duk_push_sprintf(ctx, "%d", userdata->flags);

        return 1;
    }

    return 0;
}

 /**
  * Native super setColor method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_super_prototype_setfgcolor(duk_context *ctx) {
    return tjs_super_setcolor(ctx, TJS_FLAG_UPDATE_COLOR_FG);
}

 /**
  * Native super setColor prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_super_prototype_setbgcolor(duk_context *ctx) {
    return tjs_super_setcolor(ctx, TJS_FLAG_UPDATE_COLOR_BG);
}

/**
 * Native super destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_super_dtor(duk_context *ctx) {
    /* Get userdata */
    TjsUserdata *userdata = tjs_userdata_get(ctx);

    if (NULL != userdata) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);
    }

    return 0;
}

/**
 * Native super init
 *
 * @param[inout]  ctx      A #duk_context
 * @param[inout]  control  A #TjsUserdata
 **/

void tjs_super_init(duk_context *ctx, TjsUserdata *userdata) {

    /* Register destructor */
    duk_push_this(ctx);
    duk_push_c_function(ctx, tjs_super_dtor, 0);
    duk_set_finalizer(ctx, -2);
    duk_pop(ctx);

    if (NULL != userdata) {
        TJS_LOG_DEBUG("flags=%d", userdata->flags);
    }
}