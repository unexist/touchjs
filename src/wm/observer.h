/**
 * @package TouchJS
 *
 * @file Observer header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_OBSERVER_H
#define TJS_OBSERVER_H 1

#import <Cocoa/Cocoa.h>

/* Types */
typedef void (*TjsObserverHandler)(CFStringRef notificationRef,
    AXUIElementRef elemRef);

/* Methods */
CFStringRef tjs_observer_translate_event_to_ref(const char *eventName);
const char *tjs_observer_translate_ref_to_event(CFStringRef eventRef);
AXObserverRef tjs_observer_create_from_pid(pid_t pid);
void tjs_observer_bind(AXObserverRef observerRef, AXUIElementRef elemRef,
    const char *eventName, TjsObserverHandler handler);

#endif /* TJS_OBSERVER_H */