/**
 * @package TouchJS
 *
 * @file Super header
 * @copyright (c) 2019-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_WIDGET_H
#define TJS_WIDGET_H 1

/* Includes */
#include "../libs/duktape/duktape.h"
#include "../common/userdata.h"
#include "../common/value.h"

/* Types */
typedef struct tjs_color_t {
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} TjsColor;

typedef struct tjs_widget_t {
    int flags;

    struct{
        struct tjs_color_t fg;
        struct tjs_color_t bg;
    } colors;

    union tjs_value_t value;
} TjsWidget;

/* Methods */
duk_ret_t tjs_widget_prototype_setfgcolor(duk_context *ctx);
duk_ret_t tjs_widget_prototype_setbgcolor(duk_context *ctx);

#endif /* TJS_WIDGET_H */