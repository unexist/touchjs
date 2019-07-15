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

#include "attr.h"
#include "observer.h"

/* Types */
typedef struct tjs_observation_t {
    int flags;

    /* Obj-c */
    NSString *notification;
    TjsObserverHandler handler;
} TjsObservation;

/* Globals */
NSMutableArray *observations;

/*static NSString *prettyifyEventName(NSString *event) {
  if (eventNameDict == nil) {
    eventNameDict = [NSDictionary dictionaryWithObjectsAndKeys:
    @"windowClose", [NSString stringWithFormat:@"%@", kAXUIElementDestroyedNotification],
    @"windowMove", [NSString stringWithFormat:@"%@", kAXMovedNotification],
    @"windowResize", [NSString stringWithFormat:@"%@", kAXResizedNotification],
    @"windowOpene", [NSString stringWithFormat:@"%@", kAXWindowCreatedNotification],
    @"windowFocus", [NSString stringWithFormat:@"%@", kAXFocusedWindowChangedNotification],
    @"windowTitle", [NSString stringWithFormat:@"%@", kAXTitleChangedNotification],
    @"appClose", NSWorkspaceDidTerminateApplicationNotification,
    @"appOpen", NSWorkspaceDidLaunchApplicationNotification,
    @"appHidden", NSWorkspaceDidHideApplicationNotification,
    @"appUnhidden", NSWorkspaceDidUnhideApplicationNotification,
    @"appActivate", NSWorkspaceDidActivateApplicationNotification,
    @"appDeactivate", NSWorkspaceDidDeactivateApplicationNotification, nil];
    }
  return [eventNameDict objectForKey:event];
}*/

static void tjs_observer_callback(AXObserverRef observerRef,
        AXUIElementRef elemRef, CFStringRef notificationRef, void *handler)
{
    TJS_LOG_OBSERVER("elem=%d, notification=%s",
        tjs_attr_get_win_id(elemRef), notificationRef);

    ((TjsObserverHandler)handler)(notificationRef, elemRef);
}

static AXObserverRef tjs_observer_create(pid_t pid) {
    AXObserverRef observerRef = NULL;

    AXError result = AXObserverCreate(pid,
        tjs_observer_callback, &observerRef);

    if (kAXErrorSuccess == result) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(observerRef), kCFRunLoopDefaultMode);

        observations = [NSMutableArray arrayWithCapacity: 0];

        TJS_LOG_OBSERVER("Observer created");
    }

    return observerRef;
}

void tjs_observer_add(AXUIElementRef elemRef,
    CFStringRef notificationRef, TjsObserverHandler handler)
{
    pid_t pid = tjs_attr_get_pid(elemRef);

    AXObserverRef observerRef = tjs_observer_create(pid);

    AXError result = AXObserverAddNotification(observerRef, elemRef,
        notificationRef, (__bridge void *)handler);

    if (kAXErrorSuccess == result) {
        /* Create new observation */
        TjsObservation *obs = (TjsObservation *)calloc(1, sizeof(TjsObservation));

        obs->notification = (NSString *)notificationRef;
        obs->handler = handler;

        [observations addObject: [NSValue value: &obs
            withObjCType: @encode(TjsObservation *)]];

        TJS_LOG_OBSERVER("Observer added");
    }
}