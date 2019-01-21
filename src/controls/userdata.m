/**
 * @package TouchJS
 *
 * @file Userdata functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import "../touchjs.h"

/**
 * Helper to create userdata
 *
 * @param[inout]  ctx    A #duk_context
 * @param[in]     flags  Control flags
 * @param[inout]  title. Title of the control
 *
 * @return Either #TjsControl on success; otherwise #null
 **/

 TjsControl *tjs_control_userdata_new(duk_context *ctx, int flags, const char *title) {
    /* Create new control */
    TjsControl *control = (TjsControl *)calloc(1, sizeof(TjsControl));

    control->flags = flags;
    control->idx = [_touchbarControls count];
    control->title = strdup(title);
    control->identifier = [NSString stringWithFormat:
        @"org.subforge.control%d", control->idx];

    /* Store in array */
    [_touchbarControls addObject: [NSValue value: &control
        withObjCType: @encode(TjsControl *)]];

    /* Store pointer ref */
    duk_push_this(ctx);
    duk_push_pointer(ctx, (void *) control);
    duk_put_prop_string(ctx, -2, "\xff" TJS_SYM_USERDATA);
    duk_pop(ctx);

    TJS_LOG("flags=%d, idx=%d, title=%s", control->flags, control->idx, control->title);

    return control;
 }

/**
 * Helper to get control userdata from duktape
 *
 * @param[inout]  ctx  A #duk_context
 *
 * @return Either #TjsControl on success; otherwise #null
 **/

TjsControl *tjs_control_userdata_get(duk_context *ctx) {
    /* Get userdata */
    duk_push_this(ctx);
    duk_get_prop_string(ctx, -1, "\xff" TJS_SYM_USERDATA);

    TjsControl *control = (TjsControl *)duk_get_pointer(ctx, -1);
    duk_pop_2(ctx);

    return control;
}