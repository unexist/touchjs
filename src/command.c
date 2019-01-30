/**
 * @package TouchJS
 *
 * @file Command functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "touchjs.h"

/**
 * Native label constructor
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_command_ctor(duk_context *ctx) {
    /* Sanity check */
    if (!duk_is_constructor_call(ctx)) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Create new userdata */
    TjsCommand *command = (TjsCommand *)tjs_userdata_new(ctx,
        TJS_FLAG_TYPE_COMMAND, sizeof(TjsCommand));

    if (NULL == command) {
        return DUK_RET_TYPE_ERROR;
    }

    /* Get arguments */
    command->line = strdup((char *)duk_require_string(ctx, -1));
    duk_pop(ctx);

    TJS_LOG_DUK("flags=%d", command->flags);

    return 0;
}

/**
 * Native label getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_command_prototype_getoutput(duk_context *ctx) {
    /* Get userdata */
    TjsCommand *command = (TjsCommand *)tjs_userdata_get(ctx);

    if (NULL != command) {
        TJS_LOG_DEBUG("flags=%d", command->flags);

        duk_push_string(ctx, command->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Native label getValue prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_command_prototype_tostring(duk_context *ctx) {
    /* Get userdata */
    TjsCommand *command = (TjsCommand *)tjs_userdata_get(ctx);

    if (NULL != command) {
        TJS_LOG_DEBUG("flags=%d", command->flags);

        duk_push_sprintf(ctx, "flags=%d, value=%s",
            command->flags, command->value.asChar);

        return 1;
    }

    return 0;
}

/**
 * Init methods for #TjsLabel
 *
 * @param[inout]  ctx  A #duk_context
 **/

void tjs_command_init(duk_context *ctx) {
    /* Register constructor */
    duk_push_c_function(ctx, tjs_command_ctor, 1);
    duk_push_object(ctx);

    /* Register methods */
    duk_push_c_function(ctx, tjs_command_prototype_getoutput, 0);
    duk_put_prop_string(ctx, -2, "getOutput");

    duk_push_c_function(ctx, tjs_command_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsCommand");
}