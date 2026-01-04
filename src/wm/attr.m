/**
 * @package TouchJS
 *
 * @file Attribute functions
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"
#import "attr.h"

/* Forward declaration */
AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *idOut);

/**
 * Set value for given attribute
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 * @param[in]  value    New value
 *
 * @return Either true on success; otherweise false
 **/

bool tjs_attr_set_value(AXUIElementRef elemRef, CFStringRef attrRef,
    CFTypeRef value)
{
    return (kAXErrorSuccess == AXUIElementSetAttributeValue(elemRef,
        attrRef, value));
}

/**
 * Set typed value for given attribute
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 * @param[in]  typeRef  Type of the new value
 * @param[in]  value    New value
 *
 * @return Either true on success; otherweise false
 **/

bool tjs_attr_set_typed_value(AXUIElementRef elemRef, CFStringRef attrRef,
        AXValueType typeRef, void *value)
{
    AXValueRef valueRef = AXValueCreate(typeRef, value);

    return tjs_attr_set_value(elemRef, attrRef, valueRef);
}

/**
 * Get string value from given attribute
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 * @param[in]  typeRef  Type of the value
 *
 * @return Either value on success; otherwise NULL
 **/

NSString *tjs_attr_get_string(AXUIElementRef elemRef, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(elemRef, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFStringGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

/**
 * Get number value from given attribute
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 * @param[in]  typeRef  Type of the value
 *
 * @param Either value on success; otherwise NULL
 **/

NSNumber *tjs_attr_get_number(AXUIElementRef elemRef, CFStringRef attrRef) {
    CFTypeRef typeRef;

    AXError result = AXUIElementCopyAttributeValue(elemRef, attrRef, &typeRef);

    if (kAXErrorSuccess == result && typeRef) {
        if (CFNumberGetTypeID() == CFGetTypeID(typeRef) || CFBooleanGetTypeID() == CFGetTypeID(typeRef)) {
            return CFBridgingRelease(typeRef);
        }
    }

    return NULL;
}

/**
 * Get associated pid of element
 *
 * @param[in]  elemRef  A #AXUIElementRef
 *
 * @return Either pid on success; otherwise -1
 **/

pid_t tjs_attr_get_pid(AXUIElementRef elemRef) {
    pid_t pid = -1;

    AXError result = AXUIElementGetPid(elemRef, &pid);

    if (kAXErrorSuccess != result) {
        pid = -1;
    }

    return pid;
}

/**
 * Get associated internal id of element
 *
 * @param[in]  elemRef  A #AXUIElementRef
 *
 * @return Either win id on sucess; otherwise -1
 **/

CGWindowID tjs_attr_get_win_id(AXUIElementRef elemRef) {
    CGWindowID winId;

    AXError result = _AXUIElementGetWindow(elemRef, &winId);

    if (kAXErrorSuccess != result) {
        winId = -1;
    }

    return winId;
}

/**
 * Get typed value from given attribute
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 * @param[in]  typeRef  Type of the value
 *
 * @return Either true on success; otherweise false
 **/

bool tjs_attr_get(AXUIElementRef elemRef, AXValueType typeRef,
        CFStringRef attrRef, void *value)
{
    CFTypeRef valueRef;

    AXError result = AXUIElementCopyAttributeValue(elemRef, attrRef, &valueRef);

    if (kAXErrorSuccess == result && valueRef) {
        return AXValueGetValue(valueRef, typeRef, value);
    }

    return false;
}

/**
 * Check whether attribute is settable
 *
 * @param[in]  elemRef  A #AXUIElementRef
 * @param[in]  attrRef  Name of the attribute
 *
 * @return Either true on success; otherweise false
 **/

bool tjs_attr_is_settable(AXUIElementRef elemRef, CFStringRef attrRef) {
    Boolean settable = false;
    AXError result = AXUIElementIsAttributeSettable(elemRef,
        attrRef, &settable);

    return (kAXErrorSuccess == result && settable);
}