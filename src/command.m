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

#import "touchjs.h"
#import <Cocoa/Cocoa.h>

/* Types */
typedef struct tjs_command_t {
    int flags;

    char *line;
    union tjs_value_t value;

    /* Obj-c */
    NSPipe *pipe;
} TjsCommand;

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

    tjs_super_init(ctx, (TjsUserdata *)command);

    TJS_LOG_DEBUG("flags=%d", command->flags);

    return 0;
}

/**
 * Native label exec prototype method
 *
 * @param[inout]  ctx  A #duk_context
 **/

static duk_ret_t tjs_command_prototype_exec(duk_context *ctx) {
    /* Get userdata */
    TjsCommand *command = (TjsCommand *)tjs_userdata_get(ctx);

    if (NULL != command) {
        TJS_LOG_DEBUG("flags=%d", command->flags);

        /* Create pipe */
        command->pipe = [NSPipe pipe];

        /* Split arguments */
        NSArray *args = [NSArray arrayWithObjects:
            @"-c", @"-l", [NSString stringWithUTF8String: command->line], nil];

        NSLog(@"%@", args);

        /* Get user shell */
        NSDictionary *env = [[NSProcessInfo processInfo] environment];
        NSString *shell = [env objectForKey: @"SHELL"];

        /* Create task */
        NSTask *task = [[NSTask alloc] init];

        task.launchPath = shell;
        task.arguments = args;
        task.standardOutput = command->pipe;

        [task launch];
    }

    /* Allow fluid.. */
    duk_push_this(ctx);

    return 1;
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

        /* Read output */
        NSFileHandle *file = command->pipe.fileHandleForReading;
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];

        NSString *output = [[NSString alloc] initWithData: data
            encoding: NSUTF8StringEncoding];

        command->value.asChar = strdup([output UTF8String]);

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
    duk_push_c_function(ctx, tjs_command_prototype_exec, 0);
    duk_put_prop_string(ctx, -2, "exec");

    duk_push_c_function(ctx, tjs_command_prototype_getoutput, 0);
    duk_put_prop_string(ctx, -2, "getOutput");

    duk_push_c_function(ctx, tjs_command_prototype_tostring, 0);
    duk_put_prop_string(ctx, -2, "toString");

    duk_put_prop_string(ctx, -2, "prototype");
    duk_put_global_string(ctx, "TjsCommand");
}