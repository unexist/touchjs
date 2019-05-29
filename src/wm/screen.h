/**
 * @package TouchJS
 *
 * @file Screen header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_SCREEN_H
#define TJS_SCREEN_H 1

#import <Cocoa/Cocoa.h>
#import "frame.h"

/* Types */
typedef struct tjs_screen_t {
    int flags;

    TjsFrame frame;
} TjsScreen;

#endif /* TJS_SCREEN_H */