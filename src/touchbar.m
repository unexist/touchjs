/**
 * @package TouchJS
 *
 * @file Embed functions
 * @copyright 2019 Christoph Kappel <unexist@subforge.org>
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
#include "common/callback.h"

/* Globals */
NSTouchBar *touchBar = NULL;

@implementation AppDelegate

/**
 * Handle group touchbar
 **/

- (NSTouchBar *)groupTouchBar {
    NSMutableArray *array;

    /* Create if required */
    if (NULL == touchBar) {
        NSTouchBar *groupTouchBar = [[NSTouchBar alloc] init];

        array = [NSMutableArray arrayWithCapacity: 1];

        groupTouchBar.delegate = self;
        groupTouchBar.defaultItemIdentifiers = array;

        touchBar = groupTouchBar;
    } else {
        array = [NSMutableArray arrayWithCapacity: 1];
    }

    /* Collect identifiers */
    for (int i = 0; i < tjs_embed_count(); i++) {
        TjsEmbed *embed = tjs_embed_get(i);

        /* Exclude items with a parent */
        if (NULL == embed->parent) {
            [array addObject: embed->identifier];
        }
    }

    [array addObject: kQuit];

    touchBar.defaultItemIdentifiers = array;

    return touchBar;
}

/**
 * Set group touch bar
 *
 * @param[inout]  groupTouchBar  Touchbar to add to window
 **/

-(void)setGroupTouchBar:(NSTouchBar*)groupTouchBar {
    touchBar = groupTouchBar;
}

/**
 * Handle send event: button
 *
 * @param[in]  sender  Sender of this event
 **/

- (void)button:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsEmbed *embed = tjs_embed_get(idx);

    if (NULL != embed && NULL != embed->userdata) {
        NSString *identifier;

        TJS_LOG_DEBUG("flags=%d, idx=%d", embed->userdata->flags, idx);

        /* Get object and call callback if any */
        duk_get_global_string(touch.ctx, [embed->identifier UTF8String]);

        if (duk_is_object(touch.ctx, -1)) {
            tjs_callback_call(touch.ctx, TJS_SYM_CLICK_CB, 0);
        } else {
            duk_pop(touch.ctx); ///< Tidy up
        }
    }
}

/**
 * Handle send event: slider
 *
 * @param[in]  sender  Sender of this event
 **/

- (void)slider:(id)sender {
    int idx = [sender tag];

    /* Get touch item */
    TjsEmbed *embed = tjs_embed_get(idx);

    if (NULL != embed && NULL != embed->userdata) {
        TjsWidget *widget = (TjsWidget *)embed->userdata;

        /* Update value */
        NSSlider *slider = (NSSlider *)sender;

        double value = [slider doubleValue];

        if (0 < (widget->flags & TJS_FLAG_TYPE_SLIDER)) {
            widget->value.asInt = value;
        }

        TJS_LOG_DEBUG("obj=%p, flags=%d, idx=%d, value=%lu",
            widget, widget->flags, idx, value);

        /* Get object and call callback */
        duk_get_global_string(touch.ctx, [embed->identifier UTF8String]);

        if (duk_is_object(touch.ctx, -1)) {
            duk_push_int(touch.ctx, value);
            tjs_callback_call(touch.ctx, TJS_SYM_SLIDE_CB, 1);
        } else {
            duk_pop(touch.ctx); ///< Tidy up
        }
    }
}

/**
 * Handle send event: present
 *
 * @param[in]  sender  Sender of this event
 **/

- (void)present:(id)sender {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar: self.groupTouchBar
            systemTrayItemIdentifier: kGroupButton];
    } else {
        [NSTouchBar presentSystemModalFunctionBar: self.groupTouchBar
            systemTrayItemIdentifier: kGroupButton];
    }
}

/**
 * Make items for identifiers
 *
 * @param[in]  identifier  Touch item identifier
 **/

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
       makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSCustomTouchBarItem *item = NULL;

    /* Check identifiers */
    if ([identifier isEqualToString: kQuit]) {
        item = [[NSCustomTouchBarItem alloc] initWithIdentifier: kQuit];

        item.view = [NSButton buttonWithTitle:@"Quit"
            target:[NSApplication sharedApplication]
            action: @selector(terminate:)];
    } else {
        /* Create widgets */
        for (int i = 0; i < tjs_embed_count(); i++) {
            TjsEmbed *embed = tjs_embed_get(i);

            if ([identifier isEqualToString: embed->identifier]) {
                item = [[NSCustomTouchBarItem alloc]
                    initWithIdentifier: embed->identifier];

                tjs_embed_configure(embed);
                tjs_embed_update(embed);

                item.view = embed->view;
            }
        }
    }

    return item;
}

/**
 * Handle application launch finish
 *
 * @param[inout]  aNotification  Notification sent to app
 **/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);

    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc]
        initWithIdentifier: kGroupButton];

    item.view = [NSButton buttonWithTitle:@"\U0001F4A9"
        target: self action: @selector(present:)];

    [NSTouchBarItem addSystemTrayItem:item];

    DFRElementSetControlStripPresenceForIdentifier(kGroupButton, YES);
}

/**
 * Handle application termination
 *
 * @param[inout]  aNotification  Notification sent to app
 **/

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [touchBar release];

    touchBar = NULL;
}
@end

/**
 * Attach embed item to touchbar
 *
 * @param[inout]  ctx       A #duk_context
 * @param[inout]  userdata  A #TjsUserdata
 * @param[inout]  parent    A #TjsUserdata
 **/

void tjs_touchbar_attach(duk_context *ctx, TjsUserdata *userdata,
    TjsUserdata *parent)
{
    if (NULL != userdata) {
        TJS_LOG_OBJ(userdata);

        /* Create new embed */
        TjsEmbed *embed = tjs_embed_new(userdata, parent);

        tjs_embed_create(embed);
    }
}

/**
 * Detach embed item based on userdata
 *
 * @param[inout]  ctx       A #duk_context
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_touchbar_detach(duk_context *ctx, TjsUserdata *userdata) {
    if (NULL != userdata) {
        TJS_LOG_OBJ(userdata);

        /* Find embed item */
        TjsEmbed *embed = tjs_embed_find(userdata, NULL);

        if (NULL != embed) {
            tjs_embed_destroy(embed);
        }
    }
}

/**
 * Update touchbar item based on state and userdata
 *
 * @param[inout]  userdata  A #TjsUserdata
 **/

void tjs_touchbar_update(TjsUserdata *userdata) {
    if (NULL != userdata && 0 < (userdata->flags & TJS_FLAGS_ATTACHABLE)) {
        TJS_LOG_OBJ(userdata);

        /* Find embed item */
        TjsEmbed *embed = tjs_embed_find(userdata, NULL);

        if (NULL != embed) {
            tjs_embed_update(embed);
        }
    }
}
