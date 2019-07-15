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
void tjs_observer_add(AXUIElementRef elemRef, CFStringRef notificationRef,
    TjsObserverHandler handler);

#endif /* TJS_OBSERVER_H */