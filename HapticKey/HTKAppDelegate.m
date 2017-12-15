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
#import "HTKTapGestureEventListener.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kListeningEventTypeUserDefaultsKey = @"ListeningEventType";

typedef NS_ENUM(NSUInteger, HTKAppDelegateListeningEventType) {
    HTKAppDelegateListeningEventTypeFunctionKey,
    HTKAppDelegateListeningEventTypeTapGesture
};

@interface HTKAppDelegate () <NSApplicationDelegate>

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;

@property (nonatomic, nullable) NSStatusItem *statusItem;

@property (nonatomic, nullable) NSMenuItem *functionKeyEventTypeMenuItem;
@property (nonatomic, nullable) NSMenuItem *tapGestureEventTypeMenuItem;

@end

@implementation HTKAppDelegate

- (void)setListeningEventType:(HTKAppDelegateListeningEventType)listeningEventType
{
    if (_listeningEventType != listeningEventType) {
        _listeningEventType = listeningEventType;

        [self _htk_main_updateStatusItemMenuItems];
        [self _htk_main_updateHapticFeedback];

        [self _htk_main_preserveUserDefaults];
    }
}

- (void)_htk_main_updateStatusItemMenuItems
{
    if (!self.finishedLaunching) {
        return;
    }

    self.functionKeyEventTypeMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeFunctionKey) ? NSControlStateValueOn : NSControlStateValueOff;
    self.tapGestureEventTypeMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeTapGesture) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)_htk_main_updateHapticFeedback
{
    if (!self.finishedLaunching) {
        return;
    }

    if (!AXIsProcessTrusted()) {
        return;
    }

    HTKEventListener *eventListener;
    switch (self.listeningEventType) {
        case HTKAppDelegateListeningEventTypeFunctionKey:
            eventListener = [[HTKFunctionKeyEventListener alloc] init];
            break;
        case HTKAppDelegateListeningEventTypeTapGesture:
            eventListener = [[HTKTapGestureEventListener alloc] init];
            break;
    }
    HTKHapticFeedback * const hapticFeedback = [[HTKHapticFeedback alloc] initWithEventListener:eventListener];
    hapticFeedback.enabled = YES;
    self.hapticFeedback = hapticFeedback;
}

// MARK: - User defaults

- (void)_htk_main_preserveUserDefaults
{
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.listeningEventType forKey:kListeningEventTypeUserDefaultsKey];
}

- (void)_htk_main_restoreUserDefaults
{
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
    self.listeningEventType = [defaults integerForKey:kListeningEventTypeUserDefaultsKey];
}


// MARK: - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _htk_main_restoreUserDefaults];
    [self _htk_main_loadStatusItem];

    self.finishedLaunching = YES;

    [self _htk_main_updateStatusItemMenuItems];
    [self _htk_main_updateHapticFeedback];

    if (!AXIsProcessTrusted()) {
        [self _htk_main_presentAccessibilityPermissionAlertAndTerminate];
    }
}

- (void)_htk_main_presentAccessibilityPermissionAlertAndTerminate
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

    NSMenu * const eventTypeMenu = [[NSMenu alloc] init];

    NSMenuItem * const functionKeyEventTypeMenuItem = [[NSMenuItem alloc] init];
    functionKeyEventTypeMenuItem.title = @"ESC and F1, F2, etc. Keys";
    functionKeyEventTypeMenuItem.action = @selector(_htk_action_didSelectEventTypeMenuItem:);
    functionKeyEventTypeMenuItem.target = self;
    [eventTypeMenu addItem:functionKeyEventTypeMenuItem];
    self.functionKeyEventTypeMenuItem = functionKeyEventTypeMenuItem;

    NSMenuItem * const tapGestureEventTypeMenuItem = [[NSMenuItem alloc] init];
    tapGestureEventTypeMenuItem.title = @"All Taps on Touch Bar";
    tapGestureEventTypeMenuItem.action = @selector(_htk_action_didSelectEventTypeMenuItem:);
    tapGestureEventTypeMenuItem.target = self;
    [eventTypeMenu addItem:tapGestureEventTypeMenuItem];
    self.tapGestureEventTypeMenuItem = tapGestureEventTypeMenuItem;

    NSMenuItem * const listeningEventTypeMenuItem = [[NSMenuItem alloc] init];
    listeningEventTypeMenuItem.title = @"Event";
    listeningEventTypeMenuItem.submenu = eventTypeMenu;
    [statusMenu addItem:listeningEventTypeMenuItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = @"Quit";
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    [statusItem setMenu:statusMenu];

    self.statusItem = statusItem;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

// MARK: - Actions

- (void)_htk_action_didSelectEventTypeMenuItem:(id)sender
{
    if (sender == self.functionKeyEventTypeMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeFunctionKey;
    } else if (sender == self.tapGestureEventTypeMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeTapGesture;
    }
}

@end

NS_ASSUME_NONNULL_END
