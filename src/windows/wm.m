/**
 * @package TouchJS
 *
 * @file WM functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"
#import "win.h"

/* Types */
typedef struct tjs_wm_t {
    int flags;

    /* Obj-c */
} TjsWM;

/**
 * Native constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_WM, sizeof(TjsWM));

    if (NULL == wm) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    duk_pop(ctx);

    tjs_super_init(ctx, (TjsUserdata *)wm);

    TJS_LOG_OBJ(wm);

    return 0;
}

/**
 * Native wm getWindows prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_getwindows(duk_context *ctx) {
    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);

        duk_idx_t aryIdx = duk_push_array(ctx);
        int nwins = 0;

        /* Find running applications */
        for (NSRunningApplication *runningApplication in [[NSWorkspace sharedWorkspace] runningApplications]) {
            AXUIElementRef applicationRef = AXUIElementCreateApplication(
                [runningApplication processIdentifier]);
            CFArrayRef applicationWindows;
            AXUIElementCopyAttributeValues(applicationRef, kAXWindowsAttribute,
                0, 100, &applicationWindows);

            if (!applicationWindows) continue;

            /* Find windows of application */
            for (CFIndex i = 0; i < CFArrayGetCount(applicationWindows); ++i) {
                /* Create new TjsWin object and add it to array */
                duk_get_global_string(ctx, "TjsWin");
                duk_new(ctx, 0);

                duk_dup_top(ctx);
                duk_put_prop_index(ctx, aryIdx, nwins++);

                /* Add window ref */
                TjsWin *win = (TjsWin *)tjs_userdata_from(ctx, TJS_FLAG_TYPE_WIN);

                if (NULL != win) {
                    win->ref = CFArrayGetValueAtIndex(applicationWindows, i);
                }
            }
        }

        return 1;
    }

    return 0;
}

/**
 * Native label getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);

        duk_push_sprintf(ctx, "flags=%d", wm->flags);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsWM
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_wm_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_wm_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_wm_prototype_getwindows, 0);
    duk_put_prop_string(ctx, -2, "getWindows");
    duk_push_c_function(ctx, tjs_wm_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsWM");
}