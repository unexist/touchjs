/**
 * @package TouchJS
 *
 * @file Observer functions
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
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
    { "win_open", 11, kAXWindowCreatedNotification },
    { "win_move", 11, kAXWindowMovedNotification },
    { "win_focus", 12, kAXFocusedWindowChangedNotification },
    { "win_title", 12, kAXTitleChangedNotification },
    { "win_close", 12, kAXUIElementDestroyedNotification },
    { "win_resize", 13, kAXWindowResizedNotification }
};

#define LENGTH(ary) (sizeof(ary) / sizeof(ary[0]))

/**
 * Translate event names to event references
 *
 * @param[in]  eventName  Name of the event to translate
 *
 * @return Found event reference; otherwise NULL
 **/

CFStringRef tjs_observer_translate_event_to_ref(const char *eventName) {
    for (int i = 0; i < LENGTH(events); i++) {
        if (0 == strncasecmp(eventName, events[i].eventName, events[i].len)) {
            return events[i].eventRef;
        }
    }

    return NULL;
}

/**
 * Translate event references to event names
 *
 * @param[in]  eventRef  Event reference to to translate
 *
 * @return Found event reference; otherwise NULL
 **/

const char *tjs_observer_translate_ref_to_event(CFStringRef eventRef) {
    for (int i = 0; i < LENGTH(events); i++) {
        if (kCFCompareEqualTo == CFStringCompare(events[i].eventRef, eventRef, 0)) {
            return events[i].eventName;
        }
    }

    return NULL;
}

/**
 * Helper to call observer callbacks
 *
 * @param[in]   observerRef      Observer reference
 * @param[in]   elemRef          Element reference
 * @param[in]   notificationRef .Notification reference
 * @param[in]   handler          Callback handler
 **/

static void tjs_observer_callback(AXObserverRef observerRef,
        AXUIElementRef elemRef, CFStringRef notificationRef, void *handler)
{
    TJS_LOG_OBSERVER("Callback called: elem=%d, event=%s",
        tjs_attr_get_win_id(elemRef), tjs_observer_translate_ref_to_event(notificationRef));

    ((TjsObserverHandler)handler)(notificationRef, elemRef);
}

/**
 * Create observer for given process id
 *
 * @param[in] . pid . Process id
 *
 * @return Newly created observer
 **/

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

 /**
  * Bind observer notification
  *
  * @param[in]  observerRef  Observer reference
  * @param[in]  appRef       Application reference
  * @param[in]  eventName    Name of the event
  * @param[in]  handler      Handler to call
  **/

void tjs_observer_bind(AXObserverRef observerRef, AXUIElementRef appRef,
        const char *eventName, TjsObserverHandler handler)
{
    CFStringRef notificationRef = tjs_observer_translate_event_to_ref(eventName);
    AXError result = AXObserverAddNotification(observerRef, appRef,
        notificationRef, (__bridge void *)handler);

    if (kAXErrorSuccess == result) {
        TJS_LOG_OBSERVER("Notification added: name=%s", eventName);
    }
}