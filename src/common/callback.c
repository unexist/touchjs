/**
 * @package TouchJS
 *
 * @file Callback functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#include "callback.h"

 /**
  * Helper to call given callback
  *
  * @param[inout]  ctx    A #duk_context
  * @param[in]     sym    Symbol to call if found
  * @param[in]     nargs  Number of arguments for callback
  **/

void tjs_callback_call(duk_context *ctx, const char *sym, int nargs) {
    if (duk_is_object(ctx, -1 - nargs)) {
        duk_get_prop_string(ctx, -1 - nargs, sym); ///< Update index based on number of arguments

        /* Call if callable */
        if (duk_is_callable(ctx, -1)) {
            duk_insert(ctx, -2 - nargs); ///< Insert this context based on number of arguments
            duk_pcall_method(ctx, nargs);
            duk_pop(ctx); ///< Ignore result
        }
    }
}