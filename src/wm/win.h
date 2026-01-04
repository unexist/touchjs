/**
 * @package TouchJS
 *
 * @file Win header
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_WIN_H
#define TJS_WIN_H 1

#import <Cocoa/Cocoa.h>

#include "frame.h"

/* Types */
typedef struct tjs_win_t {
    int flags;

    TjsFrame frame;

    /* Obj-c */
    AXUIElementRef elemRef;
} TjsWin;

/* Methods */
TjsWin *tjs_win_new(AXUIElementRef elemRef);

#endif /* TJS_WIN_H */