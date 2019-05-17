/**
 * @package TouchJS
 *
 * @file Win header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_WIN_ATTR_H
#define TJS_WIN_ATTR_H

#import "win.h"

bool tjs_win_attr_set(TjsWin *win, AXValueType typeRef, CFStringRef attrRef, void *value);
NSString *tjs_win_attr_get_string(TjsWin *win, CFStringRef attrRef);
NSNumber *tjs_win_attr_get_number(TjsWin *win, CFStringRef attrRef);
bool tjs_win_attr_get(TjsWin *win, AXValueType typeRef, CFStringRef attrRef, void *value);
bool tjs_win_attr_is_settable(TjsWin *win, CFStringRef attrRef);

#endif /* TJS_WIN_ATTR_H */