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

#import "../touchjs.h"

/**
 * Helper to update view based on state
 *
 * @param[inout]  control  A #TjsControl
 **/

void tjs_control_helper_update(TjsControl *control) {
    if (nil != control) {
        /* Set fg color if any */
        if (0 < (control->flags & TJS_FLAG_COLOR_FG)) {
            NSColor *fgColor = [NSColor
                colorWithDeviceRed: (control->colors.fg.red / 0xff)
                green: (control->colors.fg.green / 0xff)
                blue: (control->colors.fg.blue / 0xff)
                alpha: 1.0f];

            /* Handle control types */
            if (0 < (control->flags & TJS_FLAG_TYPE_LABEL)) {
                [(NSTextView *)control->view setTextColor: fgColor];
            }
        }

        /* Set bg color if any */
        if (0 < (control->flags & TJS_FLAG_COLOR_BG)) {
            NSColor *bgColor = [NSColor
                colorWithDeviceRed: (control->colors.bg.red / 0xff)
                green: (control->colors.bg.green / 0xff)
                blue: (control->colors.bg.blue / 0xff)
                alpha: 1.0f];

            /* Handle control types */
            if (0 < (control->flags & TJS_FLAG_TYPE_BUTTON)) {
                [((NSButton *)(control->view)) setBezelColor: bgColor];
            }
        }
    }
}

 /**
  * Native button to string prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_control_helper_tostring(duk_context *ctx) {
    duk_push_this(ctx);

    /* Get idx */
    duk_get_prop_string(ctx, -1, "idx");
    int idx = duk_get_int(ctx, -1);

    /* Get title */
    duk_get_prop_string(ctx, -2, "title");
    const char *title = duk_get_string(ctx, -1);

    duk_push_sprintf(ctx, "%s %d", title, idx);

    return 1;
}

 /**
  * Helper to set the control color
  *
  * @param[inout]  ctx   A #duk_context
  * @param[in]     flag  Color flag
  **/

duk_ret_t tjs_control_helper_setcolor(duk_context *ctx, int flag) {
    /* Fetch colors from stack */
    int blue = duk_require_int(ctx, -1);
    int green = duk_require_int(ctx, -2);
    int red = duk_require_int(ctx, -3);

    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s, red=%d, green=%d, blue=%d",
            control->idx, control->title, red, green, blue);

        /* Store color in case control isn't visible */
        TjsColor *color = nil;
        control->flags |= flag;

        if (TJS_FLAG_COLOR_FG == flag) {
            color = &(control->colors.fg);
        } else {
            color = &(control->colors.bg);
        }

        color->red = red;
        color->green = green;
        color->blue = blue;

        tjs_control_helper_update(control);
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
}

 /**
  * Native control setColor method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_control_prototype_setfgcolor(duk_context *ctx) {
    return tjs_control_helper_setcolor(ctx, TJS_FLAG_COLOR_FG);
}

 /**
  * Native control setColor prototype_method
  *
  * @param[inout]  ctx  A #duk_context
  **/

duk_ret_t tjs_control_prototype_setbgcolor(duk_context *ctx) {
    return tjs_control_helper_setcolor(ctx, TJS_FLAG_COLOR_BG);
}

/**
 * Native button destructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

duk_ret_t tjs_control_dtor(duk_context *ctx) {
    /* Get userdata */
    TjsControl *control = tjs_control_userdata_get(ctx);

    if (nil != control) {
        TJS_LOG("idx=%d, name=%s", control->idx, control->title);
    }

    return 0;
}

/**
 * Native control constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

duk_ret_t tjs_control_ctor(duk_context *ctx, int flags) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    const char *title = duk_require_string(ctx, -1);
    duk_pop(ctx);

    /* Create new userdata */
    TjsControl *control = tjs_control_userdata_new(ctx, flags, title);

    /* Set properties */
    duk_push_this(ctx);
    duk_push_int(ctx, control->idx);
    duk_put_prop_string(ctx, -2, "idx");
    duk_push_string(ctx, control->title);
    duk_put_prop_string(ctx, -2, "title");

    /* Register destructor */
    duk_push_c_function(ctx, tjs_control_dtor, 0);
    duk_set_finalizer(ctx, -2);

    /* Store object */
    const char *identifier = [control->identifier UTF8String];

    duk_push_this(ctx);
    duk_put_global_string(ctx, identifier);

    TJS_LOG("type=%d, idx=%d, name=%s",
        control->flags, control->idx, control->title);

    return 0;
}