//
//  HTKAppDelegate.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 11/30/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKAppDelegate.h"
#import "HTKFunctionKeyEventListener.h"
#import "HTKHapticFeedback.h"
#import "HTKTapGestureEventListener.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kListeningEventTypeUserDefaultsKey = @"ListeningEventType";

typedef NS_ENUM(NSUInteger, HTKAppDelegateListeningEventType) {
    HTKAppDelegateListeningEventTypeNone = 0,
    HTKAppDelegateListeningEventTypeFunctionKey,
    HTKAppDelegateListeningEventTypeTapGesture
};

static NSString * const kFeedbackTypeUserDefaultsKey = @"FeedbackType";

typedef NS_ENUM(NSUInteger, HTKAppDelegateFeedbackType) {
    HTKAppDelegateFeedbackTypeWeak = 0,
    HTKAppDelegateFeedbackTypeMedium,
    HTKAppDelegateFeedbackTypeStrong
};

@interface HTKAppDelegate () <NSApplicationDelegate>

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;
@property (nonatomic) HTKAppDelegateFeedbackType feedbackType;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;

@property (nonatomic, nullable) NSStatusItem *statusItem;

@property (nonatomic, nullable) NSMenuItem *disabledMenuItem;
@property (nonatomic, nullable) NSMenuItem *useFunctionKeyEventMenuItem;
@property (nonatomic, nullable) NSMenuItem *useTapGestureEventMenuItem;

@property (nonatomic, nullable) NSMenuItem *useWeekFeedbackMenuItem;
@property (nonatomic, nullable) NSMenuItem *useMediumFeedbackMenuItem;
@property (nonatomic, nullable) NSMenuItem *useStrongFeedbackMenuItem;

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

        [self _htk_main_updateStatusItem];
        [self _htk_main_updateHapticFeedback];

        [self _htk_main_updateUserDefaults];
    }
}

- (void)setFeedbackType:(HTKAppDelegateFeedbackType)feedbackType
{
    if (_feedbackType != feedbackType) {
        _feedbackType = feedbackType;

        [self _htk_main_updateStatusItem];
        [self _htk_main_updateHapticFeedbackType];

        [self _htk_main_updateUserDefaults];
    }
}

- (void)_htk_main_updateStatusItem
{
    if (!self.finishedLaunching) {
        return;
    }

    self.statusItem.button.appearsDisabled = self.listeningEventType == HTKAppDelegateListeningEventTypeNone;

    self.disabledMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeNone) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useFunctionKeyEventMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeFunctionKey) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useTapGestureEventMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeTapGesture) ? NSControlStateValueOn : NSControlStateValueOff;

    self.useWeekFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeWeak) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useMediumFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeMedium) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useStrongFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeStrong) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)_htk_main_updateHapticFeedback
{
    if (!self.finishedLaunching) {
        return;
    }

    HTKEventListener *eventListener = nil;
    switch (self.listeningEventType) {
        case HTKAppDelegateListeningEventTypeNone:
            break;
        case HTKAppDelegateListeningEventTypeFunctionKey:
            eventListener = [[HTKFunctionKeyEventListener alloc] init];
            break;
        case HTKAppDelegateListeningEventTypeTapGesture:
            eventListener = [[HTKTapGestureEventListener alloc] init];
            break;
    }

    if (eventListener) {
        HTKHapticFeedback * const hapticFeedback = [[HTKHapticFeedback alloc] initWithEventListener:eventListener];
        hapticFeedback.enabled = YES;
        self.hapticFeedback = hapticFeedback;
    } else {
        self.hapticFeedback = nil;
    }

    [self _htk_main_updateHapticFeedbackType];
}

- (void)_htk_main_updateHapticFeedbackType
{
    if (!self.hapticFeedback) {
        return;
    }

    switch (self.feedbackType) {
        case HTKAppDelegateFeedbackTypeWeak:
            self.hapticFeedback.type = HTKHapticFeedbackTypeWeak;
            break;
        case HTKAppDelegateFeedbackTypeMedium:
            self.hapticFeedback.type = HTKHapticFeedbackTypeMedium;
            break;
        case HTKAppDelegateFeedbackTypeStrong:
            self.hapticFeedback.type = HTKHapticFeedbackTypeStrong;
            break;
    }
}

- (void)_htk_main_updateUserDefaults
{
    if (!self.finishedLaunching) {
        return;
    }

    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];

    [defaults setInteger:self.listeningEventType forKey:kListeningEventTypeUserDefaultsKey];
    [defaults setInteger:self.feedbackType forKey:kFeedbackTypeUserDefaultsKey];
}

// MARK: - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _htk_main_loadUserDefaults];
    [self _htk_main_loadStatusItem];

    self.finishedLaunching = YES;

    [self _htk_main_updateUserDefaults];
    [self _htk_main_updateStatusItem];
    [self _htk_main_updateHapticFeedback];
}

- (void)_htk_main_loadUserDefaults
{
    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];

    // Read values from user defaults first.
    // Each property setter _MAY_ update user defaults.

    HTKAppDelegateListeningEventType listeningEventType;
    if ([defaults objectForKey:kListeningEventTypeUserDefaultsKey]) {
        listeningEventType = [defaults integerForKey:kListeningEventTypeUserDefaultsKey];
    } else {
        // Default to function key event.
        listeningEventType = HTKAppDelegateListeningEventTypeFunctionKey;
    }

    HTKAppDelegateFeedbackType feedbackType;
    if ([defaults objectForKey:kFeedbackTypeUserDefaultsKey]) {
        feedbackType = [defaults integerForKey:kFeedbackTypeUserDefaultsKey];
    } else {
        // Default to medium feedback.
        feedbackType = HTKAppDelegateFeedbackTypeMedium;
    }

    self.listeningEventType = listeningEventType;
    self.feedbackType = feedbackType;
}

- (void)_htk_main_loadStatusItem
{
    NSStatusBar * const statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem * const statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    statusItem.highlightMode = YES;

    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    statusItem.image = statusItemImage;

    NSMenu * const statusMenu = [[NSMenu alloc] init];

    NSMenuItem * const disabledMenuItem = [[NSMenuItem alloc] init];
    disabledMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_DISABLED_ITEM", @"A status menu item selected when it is disabled.");
    disabledMenuItem.action = @selector(_htk_action_didSelectListeningEventTypeMenuItem:);
    disabledMenuItem.target = self;
    [statusMenu addItem:disabledMenuItem];
    self.disabledMenuItem = disabledMenuItem;

    NSMenuItem * const useFunctionKeyEventMenuItem = [[NSMenuItem alloc] init];
    useFunctionKeyEventMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_FUNCTION_KEY_EVENT_MENU_ITEM", @"A status menu item to use function key events.");
    useFunctionKeyEventMenuItem.action = @selector(_htk_action_didSelectListeningEventTypeMenuItem:);
    useFunctionKeyEventMenuItem.target = self;
    [statusMenu addItem:useFunctionKeyEventMenuItem];
    self.useFunctionKeyEventMenuItem = useFunctionKeyEventMenuItem;

    NSMenuItem * const useTapGestureEventMenuItem = [[NSMenuItem alloc] init];
    useTapGestureEventMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_TAP_GESTURE_EVENT_MENU_ITEM", @"A status menu item to use tap gesture events.");
    useTapGestureEventMenuItem.action = @selector(_htk_action_didSelectListeningEventTypeMenuItem:);
    useTapGestureEventMenuItem.target = self;
    [statusMenu addItem:useTapGestureEventMenuItem];
    self.useTapGestureEventMenuItem = useTapGestureEventMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const useWeekFeedbackMenuItem = [[NSMenuItem alloc] init];
    useWeekFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_WEEK_FEEDBACK_MENU_ITEM", @"A status menu item to use weak feedback.");
    useWeekFeedbackMenuItem.keyEquivalent = @"1";
    useWeekFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useWeekFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useWeekFeedbackMenuItem.target = self;
    [statusMenu addItem:useWeekFeedbackMenuItem];
    self.useWeekFeedbackMenuItem = useWeekFeedbackMenuItem;

    NSMenuItem * const useMediumFeedbackMenuItem = [[NSMenuItem alloc] init];
    useMediumFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_MEDIUM_FEEDBACK_MENU_ITEM", @"A status menu item to use medium feedback.");
    useMediumFeedbackMenuItem.keyEquivalent = @"2";
    useMediumFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useMediumFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useMediumFeedbackMenuItem.target = self;
    [statusMenu addItem:useMediumFeedbackMenuItem];
    self.useMediumFeedbackMenuItem = useMediumFeedbackMenuItem;

    NSMenuItem * const useStrongFeedbackMenuItem = [[NSMenuItem alloc] init];
    useStrongFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_STRONG_FEEDBACK_MENU_ITEM", @"A status menu item to use strong feedback.");
    useStrongFeedbackMenuItem.keyEquivalent = @"3";
    useStrongFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useStrongFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useStrongFeedbackMenuItem.target = self;
    [statusMenu addItem:useStrongFeedbackMenuItem];
    self.useStrongFeedbackMenuItem = useStrongFeedbackMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_QUIT_MENU_ITEM", @"A status menu item to terminate the application.");
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    statusItem.menu = statusMenu;

    self.statusItem = statusItem;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

// MARK: - Actions

- (void)_htk_action_didSelectListeningEventTypeMenuItem:(id)sender
{
    if (sender == self.disabledMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeNone;
    } else if (sender == self.useFunctionKeyEventMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeFunctionKey;
    } else if (sender == self.useTapGestureEventMenuItem) {
        self.listeningEventType = HTKAppDelegateListeningEventTypeTapGesture;
    }
}

- (void)_htk_action_didSelectFeedbackTypeMenuItem:(id)sender
{
    if (sender == self.useWeekFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeWeak;
    } else if (sender == self.useMediumFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeMedium;
    } else if (sender == self.useStrongFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeStrong;
    }
}

@end

NS_ASSUME_NONNULL_END
