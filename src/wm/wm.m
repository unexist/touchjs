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

/* Globals */
NSMutableArray *observers;
NSMutableDictionary *registry;

/* Types */
typedef struct tjs_wm_t {
    int flags;
} TjsWM;

static void tjs_wm_create_win(AXUIElementRef elemRef) {
    /* Create new TjsWin object */
    duk_get_global_string(touch.ctx, "TjsWin");
    duk_new(touch.ctx, 0);

    /* Add window ref */
    TjsWin *win = (TjsWin *)tjs_userdata_from(touch.ctx, TJS_FLAG_TYPE_WIN);

    if (NULL != win) {
        win->elemRef = elemRef;
    }
}

static void tjs_wm_add_to_registry(const char *eventName, const char *globalName) {
    /* Add obversation */
    NSMutableArray *keys;
    NSString *objEventName = [[NSString alloc] initWithUTF8String: eventName];
    NSString *objGlobalName = [[NSString alloc] initWithBytes: globalName
        length: strlen(globalName) encoding: NSASCIIStringEncoding]; ///< Special handling for \xff

    id obj = [registry objectForKey: objEventName];

    if (obj) {
        keys = obj;
    } else {
        keys = [[NSMutableArray alloc] init];

        [registry setObject: keys forKey: objEventName];
    }

    [keys addObject: objGlobalName];
    [objEventName release];
}

static void tjs_wm_handle_event(CFStringRef notificationRef, AXUIElementRef elemRef) {
    const char *eventName = tjs_observer_translate_ref_to_event(notificationRef);

    TJS_LOG_OBSERVER("Handle event: name=%s", eventName);

    /* Call event handlers if any */
    NSString *objEventName = [[NSString alloc] initWithUTF8String: eventName];

    id array = [registry objectForKey: objEventName];

    if (array) {
        char globalName[50] = { 0 };

        snprintf(globalName, sizeof(globalName), "\xff_event_%s_cb", eventName);

        tjs_wm_create_win(elemRef);

        /* Call registered handlers */
        for (NSString *name in array) {
            duk_get_global_string(touch.ctx, globalName);

            if (duk_is_callable(touch.ctx, -1)) {
                duk_dup(touch.ctx, -2);
                duk_pcall(touch.ctx, 1);
                duk_pop(touch.ctx);
            }
        }

        duk_pop(touch.ctx);
    }

    [objEventName release];
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
                tjs_wm_create_win(CFArrayGetValueAtIndex(appWins, i));

                /* Finally add to result array */
                duk_put_prop_index(ctx, aryIdx, nwins++);
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
        for (NSScreen *objScreen in [NSScreen screens]) {
            /* Create new TjsScreen object */
            duk_get_global_string(ctx, "TjsScreen");
            duk_new(ctx, 0);

            /* Add frame*/
            TjsScreen *screen = (TjsScreen *)tjs_userdata_from(
                ctx, TJS_FLAG_TYPE_SCREEN);

            if (NULL != screen) {
                /* Frame */
                NSRect frame = [objScreen frame];

                screen->frame.x      = NSMinX(frame);
                screen->frame.y      = NSMinY(frame);
                screen->frame.width  = NSWidth(frame);
                screen->frame.height = NSHeight(frame);
            }

            /* Finally add to result array */
            duk_put_prop_index(ctx, aryIdx, nscreens++);
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
            /* Create global name */
            char globalName[50] = { 0 };

            snprintf(globalName, sizeof(globalName), "\xff_event_%s_cb", eventName);

            /* Store function globally */
            duk_put_global_string(ctx, globalName);
            duk_pop(ctx);

            tjs_wm_add_to_registry(eventName, globalName);

            TJS_LOG_OBSERVER("Added event: name=%s", eventName);
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

    /* Create observers */
    observers = [[NSMutableArray alloc] init];
    registry = [[NSMutableDictionary alloc] init];

    /* Find running applications */
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        /* Create observer */
        pid_t pid = [app processIdentifier];

        AXUIElementRef elemRef = AXUIElementCreateApplication(pid);
        AXObserverRef observerRef = tjs_observer_create_from_pid(pid);

        /* Bind events */
        tjs_observer_bind(observerRef, elemRef, "win_move", tjs_wm_handle_event);

        [observers addObject: [NSValue value: observerRef
            withObjCType: @encode(AXObserverRef)]];

        CFRelease(elemRef);
    }
}

/**
 * Deinit wm
 **/

void tjs_wm_deinit(void) {
    /* Release observers */
    for (int i = 0; i < [observers count]; i++) {
        AXObserverRef observerRef = (AXObserverRef)([[observers objectAtIndex: i] pointerValue]);

        CFRelease(observerRef);
    }
    [observers release];

    [registry release];
}