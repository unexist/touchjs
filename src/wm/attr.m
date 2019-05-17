/**
 * @package TouchJS
 *
 * @file Attribute functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"
#import "win.h"

bool tjs_win_attr_set(TjsWin *win, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    AXValueRef valueRef = AXValueCreate(typeRef, value);

    return (kAXErrorSuccess == AXUIElementSetAttributeValue(win->ref,
        attrRef, valueRef));
}

NSString *tjs_win_attr_get_string(TjsWin *win, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(win->ref, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFStringGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

NSNumber *tjs_win_attr_get_number(TjsWin *win, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(win->ref, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFNumberGetTypeID() == CFGetTypeID(typeRef) || CFBooleanGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

bool tjs_win_attr_get(TjsWin *win, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    CFTypeRef valueRef;

    AXError result = AXUIElementCopyAttributeValue(win->ref, attrRef, &valueRef);

    if (kAXErrorSuccess == result && valueRef) {
        return AXValueGetValue(valueRef, typeRef, value);
    }

    return false;
}

bool tjs_win_attr_is_settable(TjsWin *win, CFStringRef attrRef) {
    Boolean settable = false;
    AXError result = AXUIElementIsAttributeSettable(win->ref,
        attrRef, &settable);

    return (kAXErrorSuccess == result && settable);
}