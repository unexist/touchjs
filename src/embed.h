/**
 * @package TouchJS
 *
 * @file Embed header
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_EMBED_H
#define TJS_EMBED_H 1

/* Includes */
#import <Cocoa/Cocoa.h>

#include "libs/duktape/duktape.h"
#include "common/userdata.h"

/* Types */
typedef struct tjs_embed_t {
    int idx, flags;

    struct tjs_userdata_t *userdata;
    struct tjs_userdata_t *parent;

    /* Obj-c */
    NSTouchBarItemIdentifier identifier;
    NSView *view;
} TjsEmbed;

/* Methods */
TjsEmbed *tjs_embed_new(TjsUserdata *userdata, TjsUserdata *parent);
void tjs_embed_create(TjsEmbed *embed);
void tjs_embed_configure(TjsEmbed *embed);
void tjs_embed_update(TjsEmbed *embed);
void tjs_embed_color(TjsEmbed *embed);
void tjs_embed_value(TjsEmbed *embed);
void tjs_embed_destroy(TjsEmbed *embed);

TjsEmbed *tjs_embed_find(TjsUserdata *userdata, int *idx);
TjsEmbed *tjs_embed_get(int idx);
int tjs_embed_count();

void tjs_embed_init(void);
void tjs_embed_deinit(void);

#endif /* TJS_EMBED_H */