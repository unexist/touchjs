/**
 * @package TouchJS
 *
 * @file AppDelegate functions
 * @copyright (c) 2019-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv2.
 * See the file COPYING for details.
 **/

#ifndef TJS_DELEGATE_H
#define TJS_DELEGATE_H 1

#import <Cocoa/Cocoa.h>

/* Constants */
static const NSTouchBarItemIdentifier kGroupButton = @"dev.unexist.group";
static const NSTouchBarItemIdentifier kQuit = @"dev.unexist.quit";

/* Forward declarations */
extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

/* Interfaces */
@interface NSTouchBarItem ()
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
@end

@interface NSTouchBar ()
/* macOS 10.14 and above */
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

/* macOS 10.13 and below */
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);
@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTouchBarDelegate>
@end

#endif /* TJS_DELEGATE_H */
