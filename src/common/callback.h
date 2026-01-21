/**
 * @package TouchJS
 *
 * @file Callback header
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_CALLBACK_H
#define TJS_CALLBACK_H 1

/* Includes */
#include "../libs/duktape/duktape.h"
#include "syms.h"

/* Methods */
void tjs_callback_call(duk_context *ctx, const char *sym, int nargs);

#endif /* TJS_CALLBACK_H */
