/**
 * @package TouchJS
 *
 * @file Widget functions
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "../touchjs.h"

#include "../touchbar.h"

#include "widget.h"

 /**
  * Helper to set the control color
  *
  * @param[inout]  ctx   A #duk_context
  * @param[in]     flag  Color flag
  **/

static duk_ret_t tjs_widget_setcolor(duk_context *ctx, int flag) {
    /* Fetch colors from stack */
    int blue = duk_require_int(ctx, -1);
    int green = duk_require_int(ctx, -2);
    int red = duk_require_int(ctx, -3);

    /* Get context */
    TjsUserdata *userdata = tjs_userdata_get(ctx,
        TJS_FLAGS_WIDGETS);

    /* Get userdata */
    if (NULL != userdata) {
        TjsWidget *widget = (TjsWidget *)userdata;

        TJS_LOG_DEBUG("obj=%p, flags=%d, red=%d, green=%d, blue=%d",
           widget, widget->flags, red, green, blue);

        /* Store color in case control isn't visible */
        TjsColor *color = NULL;
        widget->flags |= flag;

        if (TJS_FLAG_STATE_COLOR_FG == flag) {
            color = &(widget->colors.fg);
        } else {
            color = &(widget->colors.bg);
        }

        color->red = red;
        color->green = green;
        color->blue = blue;

        tjs_touchbar_update(userdata);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native super setColor method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_widget_prototype_setfgcolor(duk_context *ctx) {
    return tjs_widget_setcolor(ctx, TJS_FLAG_STATE_COLOR_FG);
}

 /**
  * Native widget setColor prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_widget_prototype_setbgcolor(duk_context *ctx) {
    return tjs_widget_setcolor(ctx, TJS_FLAG_STATE_COLOR_BG);
}