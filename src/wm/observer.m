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

struct {
    char eventName[13];
    int len;
    CFStringRef eventRef;
} events[] = {
    { "win_close", 12, kAXUIElementDestroyedNotification },
    { "win_move", 11, kAXWindowMovedNotification },
    { "win_resize", 13, kAXWindowResizedNotification },
    { "win_open", 11, kAXWindowCreatedNotification },
    { "win_focus", 12, kAXFocusedWindowChangedNotification },
    { "win_title", 12, kAXTitleChangedNotification }
};

#define LENGTH(ary) (sizeof(ary) / sizeof(ary[0]))

CFStringRef tjs_observer_translate_event_to_ref(const char *eventName) {
    for (int i = 0; i < LENGTH(events); i++) {
        if (0 == strncasecmp(eventName, events[i].eventName, events[i].len)) {
            return events[i].eventRef;
        }
    }

    return NULL;
}

const char *tjs_observer_translate_ref_to_event(CFStringRef eventRef) {
    for (int i = 0; i < LENGTH(events); i++) {
        if (kCFCompareEqualTo == CFStringCompare(events[i].eventRef, eventRef, 0)) {
            return events[i].eventName;
        }
    }

    return NULL;
}

static void tjs_observer_callback(AXObserverRef observerRef,
        AXUIElementRef elemRef, CFStringRef notificationRef, void *handler)
{
    TJS_LOG_OBSERVER("elem=%d, event=%s",
        tjs_attr_get_win_id(elemRef), tjs_observer_translate_ref_to_event(notificationRef));

    ((TjsObserverHandler)handler)(notificationRef, elemRef);
}

AXObserverRef tjs_observer_create_from_pid(pid_t pid) {
    AXObserverRef observerRef = NULL;

    AXError result = AXObserverCreate(pid,
        tjs_observer_callback, &observerRef);

    if (kAXErrorSuccess == result) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
            AXObserverGetRunLoopSource(observerRef), kCFRunLoopDefaultMode);

        TJS_LOG_OBSERVER("Observer created: pid=%d", pid);
    }

    return observerRef;
}

void tjs_observer_bind(AXObserverRef observerRef, AXUIElementRef elemRef,
    CFStringRef notificationRef, TjsObserverHandler handler)
{
    AXError result = AXObserverAddNotification(observerRef, elemRef,
        notificationRef, (__bridge void *)handler);

    if (kAXErrorSuccess == result) {
        TJS_LOG_OBSERVER("Event added: name=%s",
            tjs_observer_translate_ref_to_event(notificationRef));
    }
}