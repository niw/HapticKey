//
//  HTKAppDelegate.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 11/30/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKAppDelegate.h"
#import "HTKHapticFeedback.h"
#import "HTKFunctionKeyEventListener.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTKAppDelegate ()

@property (nonatomic, nullable) NSStatusItem *statusItem;
@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;

@end

@implementation HTKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _htk_main_loadStatusItem];

    if (AXIsProcessTrusted()) {
        [self _htk_main_loadHapticFeedback];
    } else {
        [self _htk_main_presentAccessibilityPermissionAlert];
    }
}

- (void)_htk_main_presentAccessibilityPermissionAlert
{
    NSAlert * const alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = @"Please allow to use Accessibility on Privacy settings in the System Preferences.";
    alert.informativeText = @"To listen keyboard events, the application needs to have a permission to use Accessibility.";
    alert.alertStyle = NSAlertStyleCritical;
    // Surprisingly, this is a blocking call.
    [alert runModal];
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)_htk_main_loadStatusItem
{
    NSStatusBar * const statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem * const statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];

    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    [statusItem setImage:statusItemImage];

    NSMenu * const statusMenu = [[NSMenu alloc] init];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = @"Quit";
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    [statusItem setMenu:statusMenu];

    self.statusItem = statusItem;
}

- (void)_htk_main_loadHapticFeedback
{
    HTKHapticFeedback * const hapticFeedback = [[HTKHapticFeedback alloc] initWithEventListener:[[HTKFunctionKeyEventListener alloc] init]];
    hapticFeedback.enabled = YES;
    self.hapticFeedback = hapticFeedback;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

@end

NS_ASSUME_NONNULL_END
