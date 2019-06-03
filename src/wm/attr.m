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
#import "attr.h"

bool tjs_attr_set_value(AXUIElementRef ref, CFStringRef attrRef, CFTypeRef value)
{
    return (kAXErrorSuccess == AXUIElementSetAttributeValue(ref,
        attrRef, value));
}

bool tjs_attr_set_typed_value(AXUIElementRef ref, CFStringRef attrRef,
        AXValueType typeRef, void *value)
{
    AXValueRef valueRef = AXValueCreate(typeRef, value);

    return tjs_attr_set_value(ref, attrRef, valueRef);
}

NSString *tjs_attr_get_string(AXUIElementRef ref, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(ref, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFStringGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

NSNumber *tjs_attr_get_number(AXUIElementRef ref, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(ref, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFNumberGetTypeID() == CFGetTypeID(typeRef) || CFBooleanGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

bool tjs_attr_get(AXUIElementRef ref, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    CFTypeRef valueRef;

    AXError result = AXUIElementCopyAttributeValue(ref, attrRef, &valueRef);

    if (kAXErrorSuccess == result && valueRef) {
        return AXValueGetValue(valueRef, typeRef, value);
    }

    return false;
}

bool tjs_attr_is_settable(AXUIElementRef ref, CFStringRef attrRef) {
    Boolean settable = false;
    AXError result = AXUIElementIsAttributeSettable(ref,
        attrRef, &settable);

    return (kAXErrorSuccess == result && settable);
}