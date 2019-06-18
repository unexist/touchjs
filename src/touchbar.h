/**
 * @package TouchJS
 *
 * @file Touchbar header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_TOUCHBAR_H
#define TJS_TOUCHBAR_H 1

/* Includes */
#include "libs/duktape/duktape.h"

#include "common/userdata.h"

/* Methods */
void tjs_touchbar_attach(duk_context *ctx, TjsUserdata *userdata, TjsUserdata *parent);
void tjs_touchbar_detach(duk_context *ctx, TjsUserdata *userdata);
void tjs_touchbar_update(TjsUserdata *userdata);

#endif /* TJS_TOUCHBAR_H */