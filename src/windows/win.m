/**
 * @package TouchJS
 *
 * @file Win functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"
#import "win.h"

static bool tjs_win_attr_set(TjsWin *win, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    AXValueRef valueRef = AXValueCreate(typeRef, value);

    return (kAXErrorSuccess == AXUIElementSetAttributeValue(win->ref,
        attrRef, valueRef));
}

static NSString *tjs_win_attr_get_string(TjsWin *win, CFStringRef attr) {
    CFTypeRef ref;

    AXError result = AXUIElementCopyAttributeValue(win->ref, attr, &ref);

    if (kAXErrorSuccess == result && ref) {
        if (CFStringGetTypeID() == CFGetTypeID(ref)) {
            return CFBridgingRelease(ref);
        }
    }

    return NULL;
}

static bool tjs_win_attr_get(TjsWin *win, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    CFTypeRef valueRef;

    AXError result = AXUIElementCopyAttributeValue(win->ref, attrRef, &valueRef);

    if (kAXErrorSuccess == result && valueRef) {
        return AXValueGetValue(valueRef, typeRef, value);
    }

    return false;
}

static bool tjs_win_attr_is_settable(TjsWin *win, CFStringRef attrRef) {
    Boolean settable = false;
    AXError result = AXUIElementIsAttributeSettable(win->ref,
        attrRef, &settable);

    return (kAXErrorSuccess == result && settable);
}

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_WIN, sizeof(TjsWin));

    if (NULL == win) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    duk_pop(ctx);

    tjs_super_init(ctx, (TjsUserdata *)win);

    TJS_LOG_OBJ(win);

    return 0;
}

/**
 * Native win isMovable prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_ismovable(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        duk_push_boolean(ctx,
            (tjs_win_attr_is_settable(win, kAXPositionAttribute) ? 1 : 0));

        return 1;
    }

    return 0;
}

/**
 * Native win isResizable prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_isresizable(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        duk_push_boolean(ctx,
            (tjs_win_attr_is_settable(win, kAXSizeAttribute) ? 1 : 0));

        return 1;
    }

    return 0;
}

/**
 * Native win setXY prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_setxy(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            CGPoint point = {
                .x = duk_require_int(ctx, -1),
                .y = duk_require_int(ctx, -2)
            };

            TJS_LOG_DEBUG("x=%d, y=%d", point.x, point.y);

            tjs_win_attr_set(win, kAXValueCGPointType,
                kAXPositionAttribute, (void *)&point);
        }
    }

    return 0;
}

/**
 * Native win setWH prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_setwh(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            CGSize size = {
                .width = duk_require_int(ctx, -1),
                .height = duk_require_int(ctx, -2)
            };

            TJS_LOG_DEBUG("w=%d, h=%d", size.width, size.height);

            tjs_win_attr_set(win, kAXValueCGSizeType,
                kAXSizeAttribute, (void *)&size);
        }
    }

    return 0;
}

/**
 * Native win getRect prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_getrect(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            CGPoint point;
            CGSize size;

            tjs_win_attr_get(win, kAXValueCGPointType,
                kAXPositionAttribute, (void *)&point);
            tjs_win_attr_get(win, kAXValueCGSizeType,
                kAXSizeAttribute, (void *)&size);

            /* Add pos and size to array */
            duk_idx_t aryIdx = duk_push_array(ctx);

            duk_push_int(ctx, point.x);
            duk_put_prop_index(ctx, aryIdx, 0);
            duk_push_int(ctx, point.y);
            duk_put_prop_index(ctx, aryIdx, 1);
            duk_push_int(ctx, size.width);
            duk_put_prop_index(ctx, aryIdx, 2);
            duk_push_int(ctx, size.height);
            duk_put_prop_index(ctx, aryIdx, 3);

            return 1;
        }
    }

    return 0;
}

/**
 * Native win getTitle prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_gettitle(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            NSString *title = tjs_win_attr_get_string(win, kAXTitleAttribute);

            if (NULL != title) {
                duk_push_string(ctx, [title UTF8String]);

                return 1;
            }
        }
    }

    return 0;
}

/**
 * Native win toString prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        duk_push_sprintf(ctx, "flags=%d", win->flags);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsWin
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_win_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_win_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_win_prototype_isresizable, 0);
    duk_put_prop_string(ctx, -2, "isResizable");
    duk_push_c_function(ctx, tjs_win_prototype_ismovable, 0);
    duk_put_prop_string(ctx, -2, "isMovable");
    duk_push_c_function(ctx, tjs_win_prototype_setxy, 2);
    duk_put_prop_string(ctx, -2, "setXY");
    duk_push_c_function(ctx, tjs_win_prototype_setwh, 2);
    duk_put_prop_string(ctx, -2, "setWH");
    duk_push_c_function(ctx, tjs_win_prototype_getrect, 0);
    duk_put_prop_string(ctx, -2, "getRect");
    //duk_push_c_function(ctx, tjs_win_prototype_setrect, 1);
    //duk_put_prop_string(ctx, -2, "setRect");
    duk_push_c_function(ctx, tjs_win_prototype_gettitle, 0);
    duk_put_prop_string(ctx, -2, "getTitle");
    duk_push_c_function(ctx, tjs_win_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsWin");
}