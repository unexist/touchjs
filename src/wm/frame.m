/**
 * @package TouchJS
 *
 * @file Frame functions
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "frame.h"

void tjs_frame_to_array(TjsFrame *frame, duk_context *ctx) {
    /* Add pos and size to array */
    duk_idx_t aryIdx = duk_push_array(ctx);

    duk_push_int(ctx, frame->x);
    duk_put_prop_index(ctx, aryIdx, 0);
    duk_push_int(ctx, frame->y);
    duk_put_prop_index(ctx, aryIdx, 1);
    duk_push_int(ctx, frame->width);
    duk_put_prop_index(ctx, aryIdx, 2);
    duk_push_int(ctx, frame->height);
    duk_put_prop_index(ctx, aryIdx, 3);
}

void tjs_frame_from_array(TjsFrame *frame, duk_context *ctx) {
}