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
    HTKAppDelegateListeningEventTypeNone,
    HTKAppDelegateListeningEventTypeFunctionKey,
    HTKAppDelegateListeningEventTypeTapGesture
};

@interface HTKAppDelegate () <NSApplicationDelegate>

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;

@property (nonatomic, nullable) NSStatusItem *statusItem;

@property (nonatomic, nullable) NSMenuItem *noneEventTypeMenuItem;
@property (nonatomic, nullable) NSMenuItem *functionKeyEventTypeMenuItem;
@property (nonatomic, nullable) NSMenuItem *tapGestureEventTypeMenuItem;

@end

@implementation HTKAppDelegate

- (void)setListeningEventType:(HTKAppDelegateListeningEventType)listeningEventType
{
    if (_listeningEventType != listeningEventType) {
        _listeningEventType = listeningEventType;

        if (_listeningEventType != HTKAppDelegateListeningEventTypeNone) {
            CFDictionaryRef options = (__bridge CFDictionaryRef)@{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
            if (!AXIsProcessTrustedWithOptions(options)) {
                _listeningEventType = HTKAppDelegateListeningEventTypeNone;
            }
        }

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

    self.noneEventTypeMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeNone) ? NSControlStateValueOn : NSControlStateValueOff;
    self.functionKeyEventTypeMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeFunctionKey) ? NSControlStateValueOn : NSControlStateValueOff;
    self.tapGestureEventTypeMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeTapGesture) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)_htk_main_updateHapticFeedback
{
    if (!self.finishedLaunching) {
        return;
    }

    HTKEventListener *eventListener;
    switch (self.listeningEventType) {
        case HTKAppDelegateListeningEventTypeNone:
            return;
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

    NSMenuItem * const noneEventTypeMenuItem = [[NSMenuItem alloc] init];
    noneEventTypeMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_EVENT_TYPE_MENU_NONE_EVENT_TYPE_MENU_ITEM", @"A event type menu item for none.");
    noneEventTypeMenuItem.action = @selector(_htk_action_didSelectEventTypeMenuItem:);
    noneEventTypeMenuItem.target = self;
    [eventTypeMenu addItem:noneEventTypeMenuItem];
    self.noneEventTypeMenuItem = noneEventTypeMenuItem;

    NSMenuItem * const functionKeyEventTypeMenuItem = [[NSMenuItem alloc] init];
    functionKeyEventTypeMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_EVENT_TYPE_MENU_FUNCTION_KEY_EVENT_TYPE_MENU_ITEM", @"A event type menu item for function key event type.");
    functionKeyEventTypeMenuItem.action = @selector(_htk_action_didSelectEventTypeMenuItem:);
    functionKeyEventTypeMenuItem.target = self;
    [eventTypeMenu addItem:functionKeyEventTypeMenuItem];
    self.functionKeyEventTypeMenuItem = functionKeyEventTypeMenuItem;

    NSMenuItem * const tapGestureEventTypeMenuItem = [[NSMenuItem alloc] init];
    tapGestureEventTypeMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_EVENT_TYPE_MENU_TAP_GESTURE_EVENT_TYPE_MENU_ITEM", @"A event type menu item for tap gesture event type.");
    tapGestureEventTypeMenuItem.action = @selector(_htk_action_didSelectEventTypeMenuItem:);
    tapGestureEventTypeMenuItem.target = self;
    [eventTypeMenu addItem:tapGestureEventTypeMenuItem];
    self.tapGestureEventTypeMenuItem = tapGestureEventTypeMenuItem;

    NSMenuItem * const listeningEventTypeMenuItem = [[NSMenuItem alloc] init];
    listeningEventTypeMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_EVENT_TYPE_MENU_ITEM", @"A status menu item that has a submenu to select one of event types.");
    listeningEventTypeMenuItem.submenu = eventTypeMenu;
    [statusMenu addItem:listeningEventTypeMenuItem];

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_QUIT_MENU_ITEM", @"A status menu item to terminate the application.");
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
    if (sender == self.noneEventTypeMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeNone;
    } else if (sender == self.functionKeyEventTypeMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeFunctionKey;
    } else if (sender == self.tapGestureEventTypeMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeTapGesture;
    }
}

@end

NS_ASSUME_NONNULL_END
