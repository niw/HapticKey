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
#import "HTKLoginItem.h"
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
    HTKAppDelegateFeedbackTypeStrong,
    // NOTE: Due to backward compatibility, this enum value is intentionally not zero.
    HTKAppDelegateFeedbackTypeNone
};

static NSString * const kSoundEffectTypeUserDefaultsKey = @"SoundEffectType";

typedef NS_ENUM(NSUInteger, HTKAppDelegateSoundEffectType) {
    HTKAppDelegateSoundEffectTypeNone = 0,
    HTKAppDelegateSoundEffectTypeDefault
};

static NSString * const kScreenFlashEnabledUserDefaultsKey = @"ScreenFlashEnabled";

@interface HTKAppDelegate () <NSApplicationDelegate, HTKLoginItemDelegate>

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;
@property (nonatomic) HTKAppDelegateFeedbackType feedbackType;
@property (nonatomic) HTKAppDelegateSoundEffectType soundEffectType;
@property (nonatomic, getter=isScreenFlashEnabled) BOOL screenFlashEnabled;
@property (nonatomic, getter=isLoginItemEnabled) BOOL loginItemEnabled;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;
@property (nonatomic, nullable) HTKLoginItem *mainBundleLoginItem;

@property (nonatomic, nullable) NSStatusItem *statusItem;

@property (nonatomic, nullable) NSMenuItem *disabledMenuItem;
@property (nonatomic, nullable) NSMenuItem *useFunctionKeyEventMenuItem;
@property (nonatomic, nullable) NSMenuItem *useTapGestureEventMenuItem;

@property (nonatomic, nullable) NSMenuItem *noFeedbackMenuItem;
@property (nonatomic, nullable) NSMenuItem *useWeekFeedbackMenuItem;
@property (nonatomic, nullable) NSMenuItem *useMediumFeedbackMenuItem;
@property (nonatomic, nullable) NSMenuItem *useStrongFeedbackMenuItem;

@property (nonatomic, nullable) NSMenuItem *useSoundEffectMenuItem;
@property (nonatomic, nullable) NSMenuItem *useScreenFlashMenuItem;

@property (nonatomic, nullable) NSMenuItem *checkForUpdatesMenuItem;
@property (nonatomic, nullable) NSMenuItem *automaticallyCheckForUpdatesMenuItem;

@property (nonatomic, nullable) NSMenuItem *startOnLoginMenuItem;

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

- (void)setSoundEffectType:(HTKAppDelegateSoundEffectType)soundEffectType
{
    if (_soundEffectType != soundEffectType) {
        _soundEffectType = soundEffectType;

        [self _htk_main_updateStatusItem];
        [self _htk_main_updateSoundFeedbackType];

        [self _htk_main_updateUserDefaults];
    }
}

- (void)setScreenFlashEnabled:(BOOL)screenFlashEnabled
{
    if (_screenFlashEnabled != screenFlashEnabled) {
        _screenFlashEnabled = screenFlashEnabled;

        [self _htk_main_updateStatusItem];
        [self _htk_main_updateScreenFlashEnabled];

        [self _htk_main_updateUserDefaults];
    }
}

- (void)setLoginItemEnabled:(BOOL)loginItemEnabled
{
    if (_loginItemEnabled != loginItemEnabled) {
        _loginItemEnabled = loginItemEnabled;

        [self _htk_main_updateStatusItem];
        [self _htk_main_updateMainBundleLoginItem];
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

    self.noFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeNone) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useWeekFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeWeak) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useMediumFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeMedium) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useStrongFeedbackMenuItem.state = (self.feedbackType == HTKAppDelegateFeedbackTypeStrong) ? NSControlStateValueOn : NSControlStateValueOff;

    self.useSoundEffectMenuItem.state = (self.soundEffectType == HTKAppDelegateSoundEffectTypeDefault) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useScreenFlashMenuItem.state = (self.screenFlashEnabled) ? NSControlStateValueOn : NSControlStateValueOff;

    self.startOnLoginMenuItem.state = (self.loginItemEnabled) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // Do not allow to have a combination of settings that has no feedback effects.
    // This is a loose guard at user interface level and not really preventing to have such condition.
    if (menuItem == self.noFeedbackMenuItem) {
        if ((self.soundEffectType == HTKAppDelegateSoundEffectTypeNone) && !self.screenFlashEnabled) {
            return (self.feedbackType == HTKAppDelegateFeedbackTypeNone);
        }
    } else if (menuItem == self.useSoundEffectMenuItem) {
        if (self.feedbackType == HTKAppDelegateFeedbackTypeNone && !self.screenFlashEnabled) {
            return (self.soundEffectType == HTKAppDelegateSoundEffectTypeNone);
        }
    } else if (menuItem == self.useScreenFlashMenuItem) {
        if ((self.feedbackType == HTKAppDelegateFeedbackTypeNone) && (self.soundEffectType == HTKAppDelegateSoundEffectTypeNone)) {
            return !self.screenFlashEnabled;
        }
    }
    return YES;
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
    [self _htk_main_updateSoundFeedbackType];
    [self _htk_main_updateScreenFlashEnabled];
}

- (void)_htk_main_updateHapticFeedbackType
{
    if (!self.hapticFeedback) {
        return;
    }

    switch (self.feedbackType) {
        case HTKAppDelegateFeedbackTypeNone:
            self.hapticFeedback.type = HTKHapticFeedbackTypeNone;
            break;
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

- (void)_htk_main_updateSoundFeedbackType
{
    if (!self.hapticFeedback) {
        return;
    }

    switch (self.soundEffectType) {
        case HTKAppDelegateSoundEffectTypeNone:
            self.hapticFeedback.soundType = HTKSoundFeedbackTypeNone;
            break;
        case HTKAppDelegateSoundEffectTypeDefault:
            self.hapticFeedback.soundType = HTKSoundFeedbackTypeDefault;
            break;
    }
}

- (void)_htk_main_updateScreenFlashEnabled
{
    if (!self.hapticFeedback) {
        return;
    }

    self.hapticFeedback.screenFlashEnabled = self.screenFlashEnabled;
}

- (void)_htk_main_updateMainBundleLoginItem
{
    if (!self.finishedLaunching) {
        return;
    }

    self.mainBundleLoginItem.enabled = self.loginItemEnabled;
}

- (void)_htk_main_updateUserDefaults
{
    if (!self.finishedLaunching) {
        return;
    }

    NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];

    [defaults setInteger:self.listeningEventType forKey:kListeningEventTypeUserDefaultsKey];
    [defaults setInteger:self.feedbackType forKey:kFeedbackTypeUserDefaultsKey];
    [defaults setInteger:self.soundEffectType forKey:kSoundEffectTypeUserDefaultsKey];
    [defaults setBool:self.screenFlashEnabled forKey:kScreenFlashEnabledUserDefaultsKey];
}

// MARK: - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _htk_main_loadUserDefaults];
    [self _htk_main_loadStatusItem];
    [self _htk_main_loadMainBundleLoginItem];

    self.finishedLaunching = YES;

    [self _htk_main_updateUserDefaults];
    [self _htk_main_updateStatusItem];
    [self _htk_main_updateHapticFeedback];
    [self _htk_main_updateMainBundleLoginItem];
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

    HTKAppDelegateSoundEffectType soundEffectType;
    if ([defaults objectForKey:kSoundEffectTypeUserDefaultsKey]) {
        soundEffectType = [defaults integerForKey:kSoundEffectTypeUserDefaultsKey];
    } else {
        // Default to no sound effect.
        soundEffectType = HTKAppDelegateSoundEffectTypeNone;
    }

    BOOL screenFlashEnabled;
    if ([defaults objectForKey:kScreenFlashEnabledUserDefaultsKey]) {
        screenFlashEnabled = [defaults boolForKey:kScreenFlashEnabledUserDefaultsKey];
    } else {
        // Default to no screen flash.
        screenFlashEnabled = NO;
    }

    self.listeningEventType = listeningEventType;
    self.feedbackType = feedbackType;
    self.soundEffectType = soundEffectType;
    self.screenFlashEnabled = screenFlashEnabled;
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

    NSMenuItem * const noFeedbackMenuItem = [[NSMenuItem alloc] init];
    noFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_NO_FEEDBACK_MENU_ITEM", @"A status menu item to not use feedback.");
    noFeedbackMenuItem.keyEquivalent = @"0";
    noFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    noFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    noFeedbackMenuItem.target = self;
    [statusMenu addItem:noFeedbackMenuItem];
    self.noFeedbackMenuItem = noFeedbackMenuItem;

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

    NSMenuItem * const useSoundEffectMenuItem = [[NSMenuItem alloc] init];
    useSoundEffectMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SOUND_EFFECT_MENU_ITEM", @"A status menu item to use sound effect.");
    useSoundEffectMenuItem.action = @selector(_htk_action_didSelectSoundEffectTypeMenuItem:);
    useSoundEffectMenuItem.target = self;
    [statusMenu addItem:useSoundEffectMenuItem];
    self.useSoundEffectMenuItem = useSoundEffectMenuItem;

    NSMenuItem * const useScreenFlashMenuItem = [[NSMenuItem alloc] init];
    useScreenFlashMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SCREEN_FLASH_MENU_ITEM", @"A status menu item to use screen flash.");
    useScreenFlashMenuItem.action = @selector(_htk_action_didSelectScreenFlashMenuItem:);
    useScreenFlashMenuItem.target = self;
    [statusMenu addItem:useScreenFlashMenuItem];
    self.useScreenFlashMenuItem = useScreenFlashMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const checkForUpdatesMenuItem = [[NSMenuItem alloc] init];
    checkForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to check for updates.");
    [statusMenu addItem:checkForUpdatesMenuItem];
    self.checkForUpdatesMenuItem = checkForUpdatesMenuItem;

    NSMenuItem * const automaticallyCheckForUpdatesMenuItem = [[NSMenuItem alloc] init];
    automaticallyCheckForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_AUTOMATICALLY_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to set automatically check for updates.");
    [statusMenu addItem:automaticallyCheckForUpdatesMenuItem];
    self.automaticallyCheckForUpdatesMenuItem = automaticallyCheckForUpdatesMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const startOnLoginMenuItem = [[NSMenuItem alloc] init];
    startOnLoginMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_START_ON_LOGIN_MENU_ITEM", @"A status menu item to start application on login.");
    startOnLoginMenuItem.action = @selector(_htk_action_didSelectStartOnLoginMenuItem:);
    startOnLoginMenuItem.target = self;
    [statusMenu addItem:startOnLoginMenuItem];
    self.startOnLoginMenuItem = startOnLoginMenuItem;

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_QUIT_MENU_ITEM", @"A status menu item to terminate the application.");
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    statusItem.menu = statusMenu;

    self.statusItem = statusItem;
}

- (void)_htk_main_loadMainBundleLoginItem
{
    NSString * const mainBundlePath = [NSBundle mainBundle].bundlePath;
    HTKLoginItem * const mainBundleLoginItem = [[HTKLoginItem alloc] initWithPath:mainBundlePath];
    mainBundleLoginItem.delegate = self;
    self.mainBundleLoginItem = mainBundleLoginItem;

    self.loginItemEnabled = self.mainBundleLoginItem.enabled;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

// MARK: - HTKLoginItemDelegate

- (void)loginItemDidChange:(HTKLoginItem *)loginItem
{
    self.loginItemEnabled = self.mainBundleLoginItem.enabled;
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
    if (sender == self.noFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeNone;
    } else if (sender == self.useWeekFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeWeak;
    } else if (sender == self.useMediumFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeMedium;
    } else if (sender == self.useStrongFeedbackMenuItem) {
        self.feedbackType = HTKAppDelegateFeedbackTypeStrong;
    }
}

- (void)_htk_action_didSelectSoundEffectTypeMenuItem:(id)sender
{
    if (sender == self.useSoundEffectMenuItem) {
        // For now, there is an one sound effect and the menu item works as a boolean.
        switch (self.soundEffectType) {
            case HTKAppDelegateSoundEffectTypeNone:
                self.soundEffectType = HTKAppDelegateSoundEffectTypeDefault;
                break;
            case HTKAppDelegateSoundEffectTypeDefault:
                self.soundEffectType = HTKAppDelegateSoundEffectTypeNone;
                break;
        }
    }
}

- (void)_htk_action_didSelectScreenFlashMenuItem:(id)sender
{
    self.screenFlashEnabled = !self.screenFlashEnabled;
}

- (void)_htk_action_didSelectStartOnLoginMenuItem:(id)sender
{
    self.loginItemEnabled = !self.loginItemEnabled;
}

@end

NS_ASSUME_NONNULL_END
