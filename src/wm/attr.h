/**
 * @package TouchJS
 *
 * @file Attribute header
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_ATTR_H
#define TJS_ATTR_H 1

#import <Cocoa/Cocoa.h>

bool tjs_attr_set_value(AXUIElementRef elemRref, CFStringRef attrRef, CFTypeRef value);
bool tjs_attr_set_typed_value(AXUIElementRef elemRef, CFStringRef attrRef, AXValueType typeRef, void *value);
NSString *tjs_attr_get_string(AXUIElementRef elemRef, CFStringRef attrRef);
NSNumber *tjs_attr_get_number(AXUIElementRef elemRef, CFStringRef attrRef);
pid_t tjs_attr_get_pid(AXUIElementRef elemRef);
CGWindowID tjs_attr_get_win_id(AXUIElementRef elemRef);
bool tjs_attr_get(AXUIElementRef elemRef, AXValueType typeRef, CFStringRef attrRef, void *value);
bool tjs_attr_is_settable(AXUIElementRef elemRef, CFStringRef attrRef);

#endif /* TJS_ATTR_H */