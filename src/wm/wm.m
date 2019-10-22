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

#include "../touchjs.h"

#include "screen.h"
#include "win.h"
#include "attr.h"
#include "observer.h"

#include "../common/userdata.h"

/* Types */
typedef struct tjs_wm_t {
    int flags;

    NSMutableArray *observers;
} TjsWM;

static void tjs_wm_observe_handler(CFStringRef notificationRef, AXUIElementRef elemRef) {
    char buf[50] = { 0 };
    const char *eventName = tjs_observer_translate_ref_to_event(notificationRef);

    TJS_LOG_OBSERVER("Handle event: name=%s", eventName);

    snprintf(buf, sizeof(buf), "\xff_event_%s_cb", eventName);

    /* Create new TjsWin object and add it to array */
    duk_get_global_string(touch.ctx, "TjsWin");
    duk_new(touch.ctx, 0);

    TJS_DSTACK(touch.ctx);

    /* Add window ref */
    TjsWin *win = (TjsWin *)tjs_userdata_from(touch.ctx, TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        win->elemRef = elemRef;
    }

    TJS_DSTACK(touch.ctx);
}

static void tjs_wm_observe_init(TjsWM *wm) {
    if (NULL != wm) {
        wm->observers = [[NSMutableArray alloc] init];

        /* Find running applications */
        for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
            pid_t pid = [app processIdentifier];

            AXUIElementRef elemRef = AXUIElementCreateApplication(pid);
            AXObserverRef observerRef = tjs_observer_create_from_pid(pid);

            tjs_observer_bind(observerRef, elemRef,
                kAXWindowMovedNotification, tjs_wm_observe_handler);

            [wm->observers addObject: [NSValue value: observerRef
                withObjCType: @encode(AXObserverRef)]];
        }
    }
}

static void tjs_wm_observe_destroy(TjsWM *wm) {
    if (NULL != wm) {

    }
}

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

    tjs_userdata_init(ctx, (TjsUserdata *)wm);
    tjs_wm_observe_init(wm);

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
        for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
            AXUIElementRef elemRef = AXUIElementCreateApplication(
                [app processIdentifier]);

            CFArrayRef appWins;
            AXUIElementCopyAttributeValues(elemRef, kAXWindowsAttribute,
                0, 100, &appWins);

            if (!appWins) continue;

            /* Find windows of application */
            for (CFIndex i = 0; i < CFArrayGetCount(appWins); ++i) {
                /* Create new TjsWin object and add it to array */
                duk_get_global_string(ctx, "TjsWin");
                duk_new(ctx, 0);

                duk_dup_top(ctx);
                duk_put_prop_index(ctx, aryIdx, nwins++);

                /* Add window ref */
                TjsWin *win = (TjsWin *)tjs_userdata_from(ctx, TJS_FLAG_TYPE_WIN);

                if (NULL != win) {
                    win->elemRef = CFArrayGetValueAtIndex(appWins, i);
                }
            }
        }

        return 1;
    }

    return 0;
}

/**
 * Native wm getScreens prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_getscreens(duk_context *ctx) {
    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);

        duk_idx_t aryIdx = duk_push_array(ctx);
        int nscreens = 0;

        /* Find screens */
        for (NSScreen *screen1 in [NSScreen screens]) {
            /* Create new TjsScreen object and add it to array */
            duk_get_global_string(ctx, "TjsScreen");
            duk_new(ctx, 0);

            duk_dup_top(ctx);
            duk_put_prop_index(ctx, aryIdx, nscreens++);

            /* Add frame*/
            TjsScreen *screen2 = (TjsScreen *)tjs_userdata_from(
                ctx, TJS_FLAG_TYPE_SCREEN);

            if (NULL != screen2) {
                /* Frame */
                NSRect frame = [screen1 frame];

                screen2->frame.x      = NSMinX(frame);
                screen2->frame.y      = NSMinY(frame);
                screen2->frame.width  = NSWidth(frame);
                screen2->frame.height = NSHeight(frame);
            }
        }

        return 1;
    }

    return 0;
}

/**
 * Native wm observe prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_observe(duk_context *ctx) {
    /* Sanity check */
    duk_require_function(ctx, -1);
    const char *eventName = duk_require_string(ctx, -2);

    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);

        /* Check event name */
        CFStringRef eventRef = tjs_observer_translate_event_to_ref(eventName);

        if (NULL != eventRef) {
            /* Store event handler */
            char buf[50] = { 0 };

            snprintf(buf, sizeof(buf), "\xff_event_%s_cb", eventName);

            TJS_DSTACK(ctx);

            duk_put_global_string(ctx, buf);
            duk_pop(ctx);

            TJS_DSTACK(ctx);
        }
    }

    return 0;
}

/**
 * Native wm unobserve prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_unobserve(duk_context *ctx) {
    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);
    }

    return 0;
}

/**
 * Native wm isTrusted prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_wm_prototype_istrusted(duk_context *ctx) {
    /* Get userdata */
    TjsWM *wm = (TjsWM *)tjs_userdata_get(ctx,
        TJS_FLAG_TYPE_WM);

    if (NULL != wm) {
        TJS_LOG_OBJ(wm);

        /* Check whether we are trusted - prompt otherwise */
        NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt: @YES};

        duk_push_boolean(ctx,
            (YES == AXIsProcessTrustedWithOptions((CFDictionaryRef)options) ? 1 : 0));

        return 1;
    }

    return 0;
}

/**
 * Native wm toString prototype method
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
    duk_push_c_function(ctx, tjs_wm_prototype_getscreens, 0);
    duk_put_prop_string(ctx, -2, "getScreens");

    duk_push_c_function(ctx, tjs_wm_prototype_observe, 2);
    duk_put_prop_string(ctx, -2, "observe");
    duk_push_c_function(ctx, tjs_wm_prototype_unobserve, 1);
    duk_put_prop_string(ctx, -2, "unobserve");

    duk_push_c_function(ctx, tjs_wm_prototype_istrusted, 0);
    duk_put_prop_string(ctx, -2, "isTrusted");

    duk_push_c_function(ctx, tjs_wm_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsWM");
}