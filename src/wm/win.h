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

#ifndef TJS_WIN_H
#define TJS_WIN_H

#import <Cocoa/Cocoa.h>

/* Types */
typedef struct tjs_win_t {
    int flags;

    /* Obj-c */
    AXUIElementRef ref;
} TjsWin;

#endif /* TJS_WIN_H */