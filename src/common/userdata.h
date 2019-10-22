/**
 * @package TouchJS
 *
 * @file Userdata header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_USERDATA_H
#define TJS_USERDATA_H 1

/* Includes */
#include "../libs/duktape/duktape.h"
#include "syms.h"

/* Types */
typedef struct tjs_userdata_t {
    int flags;
} TjsUserdata;

/* Methods */
TjsUserdata *tjs_userdata_new(duk_context *ctx, int flags, size_t datasize);
TjsUserdata *tjs_userdata_get(duk_context *ctx, int flag);
TjsUserdata *tjs_userdata_from(duk_context *ctx, int flag);

void tjs_userdata_init(duk_context *ctx, TjsUserdata *userdata);
void tjs_userdata_destroy(TjsUserdata *userdata);

#endif /* TJS_USERDATA_H */