/**
 * @package TouchJS
 *
 * @file Embed functions
 * @copyright (c) 2019-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#import <Cocoa/Cocoa.h>

#include "touchjs.h"
#include "delegate.h"
#include "embed.h"
#include "widgets/widget.h"

/* Globals */
static NSMutableArray *embedded = NULL;

/**
 * Create new embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 * @param[in]     idx    Element index
 **/

TjsEmbed *tjs_embed_new(TjsUserdata *userdata, TjsUserdata *parent) {
    /* Create new embed */
    TjsEmbed *embed = (TjsEmbed *)calloc(1, sizeof(TjsEmbed));

    embed->idx = tjs_embed_count();
    embed->flags = TJS_FLAG_TYPE_EMBED;
    embed->userdata = userdata;
    embed->parent = parent;
    embed->identifier = [NSString stringWithFormat:
        @"org.subforge.embed%d", embed->idx];

    /* Store in array */
    [embedded addObject: [NSValue value: &embed
        withObjCType: @encode(TjsEmbed *)]];

    /* Store global in context */
    duk_put_global_string(touch.ctx, [embed->identifier UTF8String]);

    return embed;
}

/**
 * Create view of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

void tjs_embed_create(TjsEmbed *embed) {
    /* Sanity check */
    if (NULL != embed &&
            0 < (embed->flags & TJS_FLAG_TYPE_EMBED) &&
            0 == (embed->flags & TJS_FLAG_STATE_CREATED) &&
            NULL != embed->userdata)
    {
        /* Get delegate as target */
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];

        /* Handle type */
        if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_LABEL)) { ///< TjsLabel
            embed->view = [NSTextField labelWithString:
                [NSString stringWithUTF8String: ((TjsWidget *)embed->userdata)->value.asChar]];

            [((NSTextField *)embed->view) setTag: embed->idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_BUTTON)) { ///< TjsButton
            embed->view = [NSButton buttonWithTitle:
                [NSString stringWithUTF8String: ((TjsWidget *)embed->userdata)->value.asChar]
                target: delegate action: @selector(button:)];

            [((NSButton *)embed->view) setTag: embed->idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SLIDER)) { ///< TjsSlider
            embed->view = [NSSlider sliderWithValue: ((TjsWidget *)embed->userdata)->value.asInt
                minValue: 0 maxValue: 100 target: delegate action: @selector(slider:)];

            [((NSSlider *)embed->view) setTag: embed->idx];
        } else if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SCRUBBER)) {
            embed->view = [[NSScrollView alloc] initWithFrame: CGRectMake(0, 0, 400, 30)];
        }

        /* Mark as ready and update it */
        embed->flags |= TJS_FLAG_STATE_CREATED;
    }
}

/**
 * Update embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

void tjs_embed_update(TjsEmbed *embed) {
    if (NULL != embed && 0 < (embed->flags & TJS_FLAG_TYPE_EMBED)) {
        tjs_embed_color(embed);
        tjs_embed_value(embed);
    }
}

/**
 * Configure view of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

 void tjs_embed_configure(TjsEmbed *embed) {
    /* Sanity check */
    if (NULL != embed &&
        0 < (embed->flags & TJS_FLAG_TYPE_EMBED) &&
        0 == (embed->flags & TJS_FLAG_STATE_CONFIGURED) && NULL != embed->userdata)
    {
        /* Handle type */
        if (0 < (embed->userdata->flags & TJS_FLAG_TYPE_SCRUBBER)) {
            TjsWidget *widget = (TjsWidget *)(embed->userdata);

            NSMutableDictionary *constraintViews = [NSMutableDictionary dictionary];
            NSView *docView = [[NSView alloc] initWithFrame: NSZeroRect];
            NSSize size = NSMakeSize(8, 30);

            /* Build format and collect children */
            NSString *layoutFormat = @"H:|-8-";

            for (int i = 0; i < tjs_embed_count(); i++) {
                TjsEmbed *childEmbed = tjs_embed_get(i);

                if (NULL != childEmbed && childEmbed->parent == embed->userdata) {
                    [childEmbed->view setTranslatesAutoresizingMaskIntoConstraints: NO];
                    [docView addSubview: childEmbed->view];

                    /* Append constraint */
                    NSString *identifier = [NSString stringWithFormat: @"widget%d", i];

                    layoutFormat = [layoutFormat stringByAppendingString:
                        [NSString stringWithFormat: @"[%@]-8-", identifier]];

                    [constraintViews setObject: childEmbed->view forKey: identifier];

                    size.width += 8 + childEmbed->view.intrinsicContentSize.width + 8;

                    tjs_embed_update(childEmbed);
                }
            }

            layoutFormat = [layoutFormat stringByAppendingString: [NSString stringWithFormat:@"|"]];

            /* Add layout constraint */
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat: layoutFormat
                options: NSLayoutFormatAlignAllCenterY metrics: nil views: constraintViews];

            [docView setFrame: NSMakeRect(0, 0, size.width, size.height)];
            [docView addConstraints: constraints];

            ((NSScrollView *)embed->view).documentView = docView;
        }

        /* Mark as configured */
        embed->flags |= TJS_FLAG_STATE_CONFIGURED;
    }
 }

/**
 * Update color of touch item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

void tjs_embed_color(TjsEmbed *embed) {
    /* Sanity checks */
    if (NULL != embed &&
        0 < (embed->flags & TJS_FLAG_TYPE_EMBED) && NULL != embed->userdata &&
        0 < (embed->userdata->flags & TJS_FLAGS_COLORS))
    {
        TjsWidget *widget = (TjsWidget *)(embed->userdata);
        TjsColor *col = NULL;

        /* Selct fg or bg */
        if (0 < (widget->flags & TJS_FLAG_STATE_COLOR_FG)) {
            col = &(widget->colors.fg);
        } else {
            col = &(widget->colors.bg);
        }

        /* Parse color */
        NSColor *parsedCol = [NSColor
            colorWithRed: ((float)(col->red) / 0xff)
            green: ((float)(col->green) / 0xff)
            blue: ((float)(col->blue) / 0xff)
            alpha: 1.0f];

        /* Handle widget types */
        if (0 < (widget->flags & TJS_FLAG_STATE_COLOR_FG)) {
            if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) {
                [((NSTextView *)(embed->view)) setTextColor: parsedCol];
            }
        } else {
            if (0 < (widget->flags & TJS_FLAG_TYPE_BUTTON)) {
                [((NSButton *)(embed->view)) setBezelColor: parsedCol];
            } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
                [((NSSlider *)(embed->view)) setTrackFillColor: parsedCol];
                [((NSSlider *)(embed->view)) setNeedsDisplay];
            }
        }

        /* Remove flags if ready */
        if (0 < (embed->flags & TJS_FLAG_STATE_CREATED)) {
            widget->flags &= ~TJS_FLAGS_COLORS;
        }
    }
}

/**
 * Update value of embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

void tjs_embed_value(TjsEmbed *embed) {
    /* Sanity check */
    if (NULL != embed &&
        0 < (embed->flags & TJS_FLAG_TYPE_EMBED) && NULL != embed->userdata &&
        0 < (embed->userdata->flags & TJS_FLAG_STATE_VALUE))
    {
        TjsWidget *widget = (TjsWidget *)(embed->userdata);

        /* Handle widget types */
        if (0 < (widget->flags & TJS_FLAG_TYPE_LABEL)) {
            [((NSTextField *)(embed->view)) setStringValue:
                [NSString stringWithUTF8String: widget->value.asChar]];
        } else if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            [((NSSlider *)(embed->view)) setDoubleValue: widget->value.asInt];
        }

        /* Remove flags if ready */
        if (0 < (embed->flags & TJS_FLAG_STATE_CREATED)) {
            widget->flags &= ~TJS_FLAG_STATE_VALUE;
        }
    }
}

/**
 * Destroy given embed item
 *
 * @param[inout]  embed  A #TjsEmbed
 **/

void tjs_embed_destroy(TjsEmbed *embed) {
    if (NULL != embed && 0 < (embed->flags & TJS_FLAG_TYPE_EMBED)) {
        /* Overwrite global string with null aka remove it */
        duk_push_null(touch.ctx);
        duk_put_global_string(touch.ctx, [embed->identifier UTF8String]);

        tjs_userdata_destroy(embed->userdata);

        free(embed);
    }
}

/**
 * Get count of elements
 *
 * @return Number of elements
 **/

int tjs_embed_count(void) {
    int count = 0;

    if (NULL != embedded) {
        count = [embedded count];
    }

    return count;
}

/**
 * Find embed item based on userdata
 *
 * @param[in]   userdata  A #TjsUserdata
 * @param[out]  idx       Idx of found item; otherwise -1
 *
 * @return Either found #TjsEmbed; otherwise NULL
 **/

TjsEmbed *tjs_embed_find(TjsUserdata *userdata, int *idx) {
    for (int i = 0; i < tjs_embed_count(); i++) {
        TjsEmbed *embed = tjs_embed_get(i);

        if (embed->userdata == userdata) {
            /* Copy idx */
            if (NULL != idx) {
                *idx = i;
            }

            return embed;
        }
    }

    /* Mark as not found */
    if (NULL != idx) {
        *idx = -1;
    }

    return NULL;
}

/**
 * Get embed based on index
 *
 * @param[in]  idx  Index to get
 *
 * @return Either found #TjsEmbed; otherwise #NULL
 **/

TjsEmbed *tjs_embed_get(int idx) {
    TjsEmbed *embed = NULL;

    /* Check bounds */
    if (0 <= idx && idx < tjs_embed_count()) {
        embed = (TjsEmbed *)([[embedded objectAtIndex: idx] pointerValue]);
    }

    return embed;
}

/**
 * Init embeddng
 **/

void tjs_embed_init(void) {
    embedded = [NSMutableArray arrayWithCapacity: 0];
}

/**
 * Deinit embeddng
 **/

void tjs_embed_deinit(void) {
    for (int i = 0; i < tjs_embed_count(); i++) {
        TjsEmbed *embed = tjs_embed_get(i);

        tjs_embed_destroy(embed);
    }
}