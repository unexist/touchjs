/**
 * @package TouchJS
 *
 * @file Value header
 * @copyright (c) 2019-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_VALUE_H
#define TJS_VALUE_H 1

/* Types */
typedef union tjs_value_t {
    char *asChar;
    int asInt;
    double asDouble;
} TjsValue;

#endif /* TJS_VALUES_H */