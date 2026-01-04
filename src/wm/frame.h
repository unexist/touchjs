/**
 * @package TouchJS
 *
 * @file Frame header
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_FRAME_H
#define TJS_FRAME_H 1

#import "../libs/duktape/duktape.h"

/* Types */
typedef struct tjs_frame_t {
    int flags;

    unsigned int x, y, width, height;
} TjsFrame;

void tjs_frame_to_array(TjsFrame *frame, duk_context *ctx);
void tjs_frame_from_array(TjsFrame *frame, duk_context *ctx);

#endif /* TJS_FRAME_H */