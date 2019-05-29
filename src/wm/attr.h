/**
 * @package TouchJS
 *
 * @file Attribute header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_ATTR_H
#define TJS_ATTR_H 1

#import <Cocoa/Cocoa.h>

bool tjs_attr_set(AXUIElementRef ref, AXValueType typeRef, CFStringRef attrRef, void *value);
NSString *tjs_attr_get_string(AXUIElementRef ref, CFStringRef attrRef);
NSNumber *tjs_attr_get_number(AXUIElementRef ref, CFStringRef attrRef);
bool tjs_attr_get(AXUIElementRef ref, AXValueType typeRef, CFStringRef attrRef, void *value);
bool tjs_attr_is_settable(AXUIElementRef ref, CFStringRef attrRef);

#endif /* TJS_ATTR_H */