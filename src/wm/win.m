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
#import "attr.h"

/* Flags */
#define TJS_WIN_SIGNAL_SHOW      (1 << 0)
#define TJS_WIN_SIGNAL_HIDE      (1 << 1)
#define TJS_WIN_SIGNAL_KILL      (1 << 2)
#define TJS_WIN_SIGNAL_TERMINATE (1 << 3)

static duk_ret_t tjs_win_is_settable(duk_context *ctx, CFStringRef attrRef) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        duk_push_boolean(ctx,
            (tjs_attr_is_settable(win->ref, attrRef) ? 1 : 0));

        return 1;
    }

    return 0;
}

static duk_ret_t tjs_win_has_role(duk_context *ctx, CFStringRef attrRef,
        CFStringRef roleRef)
{
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            NSString *role = tjs_attr_get_string(win->ref, attrRef);

            if (NULL != role) {
                duk_push_boolean(ctx,
                    (YES == [role isEqualToString: (NSString *)roleRef] ? 1 : 0));

                return 1;
            }
        }
    }

    return 0;
}

static duk_ret_t tjs_win_has_attr(duk_context *ctx, CFStringRef attrRef) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        NSNumber *number = tjs_attr_get_number(win->ref, attrRef);
        Boolean isHidden = [number boolValue];

        duk_push_boolean(ctx, (YES == isHidden ? 1 : 0));

        return 1;
    }

    return 0;
}

static pid_t tjs_win_get_pid(TjsWin *win) {
    pid_t pid = -1;

    AXError result= AXUIElementGetPid(win->ref, &pid);

    if (kAXErrorSuccess != result) {
        pid = -1;
    }

    return pid;
}

static duk_ret_t tjs_win_signal(duk_context *ctx, int signal) {
     /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        pid_t pid = tjs_win_get_pid(win);

        if (-1 != pid) {
            switch (signal) {
                case TJS_WIN_SIGNAL_SHOW:
                    [[NSRunningApplication runningApplicationWithProcessIdentifier: pid] unhide];
                    break;

                case TJS_WIN_SIGNAL_HIDE:
                    [[NSRunningApplication runningApplicationWithProcessIdentifier: pid] hide];
                    break;

                case TJS_WIN_SIGNAL_KILL:
                    [[NSRunningApplication runningApplicationWithProcessIdentifier: pid] terminate];
                    break;

                case TJS_WIN_SIGNAL_TERMINATE:
                    [[NSRunningApplication runningApplicationWithProcessIdentifier: pid] forceTerminate];
                    break;
            }
        }
    }

    return 0;
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
    return tjs_win_is_settable(ctx, kAXPositionAttribute);
}

/**
 * Native win isResizable prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_isresizable(duk_context *ctx) {
    return tjs_win_is_settable(ctx, kAXSizeAttribute);
}

/**
 * Native win isHidden prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_ishidden(duk_context *ctx) {
    return tjs_win_has_attr(ctx, kAXHiddenAttribute);
}

/**
 * Native win isMinimized prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_isminimized(duk_context *ctx) {
    return tjs_win_has_attr(ctx, kAXMinimizedAttribute);
}

/**
 * Native win isNormalWindow prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_isnormalwindow(duk_context *ctx) {
    return tjs_win_has_role(ctx, kAXSubroleAttribute, kAXStandardWindowSubrole);
}

/**
 * Native win isSheet prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_issheet(duk_context *ctx) {
    return tjs_win_has_role(ctx, kAXRoleAttribute, kAXSheetRole);
}

/**
 * Native win minimize prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_minimize(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        tjs_attr_set_value(win->ref,
            (CFStringRef)NSAccessibilityMinimizedAttribute, kCFBooleanTrue);
    }

    return 0;
}

/**
 * Native win unminimize prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_unminimize(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        tjs_attr_set_value(win->ref,
            (CFStringRef)NSAccessibilityMinimizedAttribute, kCFBooleanFalse);
    }

    return 0;
}

/**
 * Native win focus prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_focus(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            NSRunningApplication *app = [NSRunningApplication
                runningApplicationWithProcessIdentifier: tjs_win_get_pid(win)];

            BOOL success = [app activateWithOptions:
                NSApplicationActivateAllWindows|NSApplicationActivateIgnoringOtherApps];

            if (!success) {
                tjs_attr_set_value(win->ref,
                    (CFStringRef)NSAccessibilityMainAttribute, kCFBooleanTrue);
            }
        }
    }

    return 0;
}

/**
 * Native win show prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_show(duk_context *ctx) {
    return tjs_win_signal(ctx, TJS_WIN_SIGNAL_SHOW);
}

/**
 * Native win hide prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_hide(duk_context *ctx) {
    return tjs_win_signal(ctx, TJS_WIN_SIGNAL_HIDE);
}

/**
 * Native win kill prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_kill(duk_context *ctx) {
    return tjs_win_signal(ctx, TJS_WIN_SIGNAL_KILL);
}

/**
 * Native win terminate prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_terminate(duk_context *ctx) {
    return tjs_win_signal(ctx, TJS_WIN_SIGNAL_TERMINATE);
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
            TJS_DSTACK(ctx);

            CGPoint point = {
                .x = duk_require_int(ctx, -1),
                .y = duk_require_int(ctx, -2)
            };

            TJS_LOG_DUK("x=%f, y=%f", point.x, point.y);

            tjs_attr_set_typed_value(win->ref, kAXPositionAttribute,
                kAXValueCGPointType, (void *)&point);
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

            TJS_LOG_DEBUG("w=%f, h=%f", size.width, size.height);

            tjs_attr_set_typed_value(win->ref, kAXSizeAttribute,
                kAXValueCGSizeType, (void *)&size);
        }
    }

    return 0;
}

/**
 * Native win getFrame prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_getframe(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            CGPoint point;
            CGSize size;

            tjs_attr_get(win->ref, kAXValueCGPointType,
                kAXPositionAttribute, (void *)&point);
            tjs_attr_get(win->ref, kAXValueCGSizeType,
                kAXSizeAttribute, (void *)&size);

            win->frame.x      = point.x;
            win->frame.y      = point.y;
            win->frame.width  = size.width;
            win->frame.height = size.height;

            tjs_frame_to_array(&(win->frame), ctx);

            return 1;
        }
    }

    return 0;
}

/**
 * Native win setFrame prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_setframe(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            TjsFrame frame;
            CGPoint point;
            CGSize size;

            tjs_frame_from_array(&frame, ctx);

            point.x = frame.x;
            point.y = frame.y;
            size.width = frame.width;
            size.height = frame.height;

            tjs_attr_set_typed_value(win->ref, kAXPositionAttribute,
                kAXValueCGPointType, (void *)&point);
            tjs_attr_set_typed_value(win->ref, kAXSizeAttribute,
                kAXValueCGSizeType, (void *)&size);

            return 0;
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
            NSString *title = tjs_attr_get_string(win->ref, kAXTitleAttribute);

            if (NULL != title) {
                duk_push_string(ctx, [title UTF8String]);

                return 1;
            }
        }
    }

    return 0;
}

/**
 * Native win getRole prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_getrole(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            NSString *role = tjs_attr_get_string(win->ref, kAXRoleAttribute);

            if (NULL != role) {
                duk_push_string(ctx, [role UTF8String]);

                return 1;
            }
        }
    }

    return 0;
}

/**
 * Native win getSubrole prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_getsubrole(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            NSString *subrole = tjs_attr_get_string(win->ref, kAXSubroleAttribute);

            if (NULL != subrole) {
                duk_push_string(ctx, [subrole UTF8String]);

                return 1;
            }
        }
    }

    return 0;
}

/**
 * Native win getPid prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_win_prototype_getpid(duk_context *ctx) {
    /* Get userdata */
    TjsWin *win = (TjsWin *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        TJS_LOG_OBJ(win);

        if (NULL != win->ref) {
            pid_t pid = tjs_win_get_pid(win);

            duk_push_int(ctx, (int)pid);

           return 1;
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

    /* Modifiers */
    duk_push_c_function(ctx, tjs_win_prototype_isresizable, 0);
    duk_put_prop_string(ctx, -2, "isResizable");
    duk_push_c_function(ctx, tjs_win_prototype_ismovable, 0);
    duk_put_prop_string(ctx, -2, "isMovable");
    duk_push_c_function(ctx, tjs_win_prototype_ishidden, 0);
    duk_put_prop_string(ctx, -2, "isHidden");
    duk_push_c_function(ctx, tjs_win_prototype_isminimized, 0);
    duk_put_prop_string(ctx, -2, "isMinimized");

    /* Types */
    duk_push_c_function(ctx, tjs_win_prototype_isnormalwindow, 0);
    duk_put_prop_string(ctx, -2, "isNormalWindow");
    duk_push_c_function(ctx, tjs_win_prototype_issheet, 0);
    duk_put_prop_string(ctx, -2, "isSheet");

    /* Actions */
    duk_push_c_function(ctx, tjs_win_prototype_focus, 0);
    duk_put_prop_string(ctx, -2, "focus");
    duk_push_c_function(ctx, tjs_win_prototype_minimize, 0);
    duk_put_prop_string(ctx, -2, "minimize");
    duk_push_c_function(ctx, tjs_win_prototype_unminimize, 0);
    duk_put_prop_string(ctx, -2, "unminimize");
    duk_push_c_function(ctx, tjs_win_prototype_show, 0);
    duk_put_prop_string(ctx, -2, "show");
    duk_push_c_function(ctx, tjs_win_prototype_hide, 0);
    duk_put_prop_string(ctx, -2, "hide");
    duk_push_c_function(ctx, tjs_win_prototype_kill, 0);
    duk_put_prop_string(ctx, -2, "kill");
    duk_push_c_function(ctx, tjs_win_prototype_terminate, 0);
    duk_put_prop_string(ctx, -2, "terminate");

    /* Geometry */
    duk_push_c_function(ctx, tjs_win_prototype_setxy, 2);
    duk_put_prop_string(ctx, -2, "setXY");
    duk_push_c_function(ctx, tjs_win_prototype_setwh, 2);
    duk_put_prop_string(ctx, -2, "setWH");

    duk_push_c_function(ctx, tjs_win_prototype_getframe, 0);
    duk_put_prop_string(ctx, -2, "getFrame");
    duk_push_c_function(ctx, tjs_win_prototype_setframe, 1);
    duk_put_prop_string(ctx, -2, "setFrame");

    /* Identifier */
    duk_push_c_function(ctx, tjs_win_prototype_gettitle, 0);
    duk_put_prop_string(ctx, -2, "getTitle");
    duk_push_c_function(ctx, tjs_win_prototype_getrole, 0);
    duk_put_prop_string(ctx, -2, "getRole");
    duk_push_c_function(ctx, tjs_win_prototype_getsubrole, 0);
    duk_put_prop_string(ctx, -2, "getSubrole");

    duk_push_c_function(ctx, tjs_win_prototype_getpid, 0);
    duk_put_prop_string(ctx, -2, "getPid");

    duk_push_c_function(ctx, tjs_win_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsWin");
}