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

@import Sparkle;

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

static const char kStatusItemVisibleKeyObservingTag;
static NSString * const kStatusItemVisibleKeyPath = @"visible";

@interface HTKAppDelegate () <NSApplicationDelegate, HTKLoginItemDelegate>

@property (nonatomic, readonly) SUUpdater *updater;

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;
@property (nonatomic) HTKAppDelegateFeedbackType feedbackType;
@property (nonatomic) HTKAppDelegateSoundEffectType soundEffectType;
@property (nonatomic, getter=isScreenFlashEnabled) BOOL screenFlashEnabled;
@property (nonatomic, getter=isLoginItemEnabled) BOOL loginItemEnabled;
@property (nonatomic, getter=isAutomaticallyCheckForUpdatesEnabled) BOOL automaticallyCheckForUpdatesEnabled;
@property (nonatomic, getter=isStatusBarIconVisible) BOOL statusBarIconVisible;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;
@property (nonatomic, nullable) HTKLoginItem *mainBundleLoginItem;

@property (nonatomic, nullable) NSStatusItem *statusItem;
// See `observeValueForKeyPath:ofObject:change:context:`.
@property (nonatomic) BOOL lastStatusItemVisible;

@property (nonatomic) NSSet<NSMenuItem *> *feedbackPreferencesMenuItemSet;

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
@property (nonatomic, nullable) NSMenuItem *showStatusBarIconMenuItem;

@end

@implementation HTKAppDelegate

- (instancetype)init
{
    if (self = [super init]) {
        _updater = [[SUUpdater alloc] init];
        _feedbackPreferencesMenuItemSet = [[NSSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (self.statusItem) {
        [self.statusItem removeObserver:self forKeyPath:kStatusItemVisibleKeyPath context:(void *)&kStatusItemVisibleKeyObservingTag];
    }
}

// MARK: - Properties

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

- (BOOL)isAutomaticallyCheckForUpdatesEnabled
{
    return self.updater.automaticallyChecksForUpdates;
}

- (void)setAutomaticallyCheckForUpdatesEnabled:(BOOL)automaticallyCheckForUpdatesEnabled
{
    if (self.updater.automaticallyChecksForUpdates != automaticallyCheckForUpdatesEnabled) {
        self.updater.automaticallyChecksForUpdates = automaticallyCheckForUpdatesEnabled;

        [self _htk_main_updateStatusItem];
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

- (void)setStatusBarIconVisible:(BOOL)statusBarIconVisible
{
    if (_statusBarIconVisible != statusBarIconVisible) {
        _statusBarIconVisible = statusBarIconVisible;

        [self _htk_main_updateStatusItem];

        if (!_statusBarIconVisible) {
            [self _htk_main_alertHidingStatusBarIcon];
        }
    }
}

- (void)_htk_main_alertHidingStatusBarIcon
{
    NSAlert * const alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = NSLocalizedString(@"ALERT_HIDING_STATUS_BAR_ICON_MESSAGE_TEXT", @"A title text for warning about hiding icon in menu bar.");;
    alert.informativeText = NSLocalizedString(@"ALERT_HIDING_STATUS_BAR_ICON_INFORMATIVE_TEXT", @"A body text for warning about hiding icon in menu bar.");

    // Workaround to avoid potentail application crash.
    // See `_htk_action_didSelectCheckForUpdates:` for the details.
    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
}

- (void)_htk_main_updateStatusItem
{
    if (!self.finishedLaunching) {
        return;
    }

    const BOOL disabled = self.listeningEventType == HTKAppDelegateListeningEventTypeNone;

    self.statusItem.button.appearsDisabled = disabled;

    self.disabledMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeNone) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useFunctionKeyEventMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeFunctionKey) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useTapGestureEventMenuItem.state = (self.listeningEventType == HTKAppDelegateListeningEventTypeTapGesture) ? NSControlStateValueOn : NSControlStateValueOff;

    self.noFeedbackMenuItem.state = (!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeNone) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useWeekFeedbackMenuItem.state = (!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeWeak) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useMediumFeedbackMenuItem.state = (!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeMedium) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useStrongFeedbackMenuItem.state = (!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeStrong) ? NSControlStateValueOn : NSControlStateValueOff;

    self.useSoundEffectMenuItem.state = (!disabled && self.soundEffectType == HTKAppDelegateSoundEffectTypeDefault) ? NSControlStateValueOn : NSControlStateValueOff;
    self.useScreenFlashMenuItem.state = (!disabled && self.screenFlashEnabled) ? NSControlStateValueOn : NSControlStateValueOff;

    self.automaticallyCheckForUpdatesMenuItem.state = (self.automaticallyCheckForUpdatesEnabled) ? NSControlStateValueOn : NSControlStateValueOff;

    self.startOnLoginMenuItem.state = (self.loginItemEnabled) ? NSControlStateValueOn : NSControlStateValueOff;
    self.showStatusBarIconMenuItem.state = (self.statusBarIconVisible) ? NSControlStateValueOn : NSControlStateValueOff;

    self.statusItem.visible = self.statusBarIconVisible;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // Disable any menu items for configuration when no events are listened.
    if ([self.feedbackPreferencesMenuItemSet containsObject:menuItem]) {
        if (self.listeningEventType == HTKAppDelegateListeningEventTypeNone) {
            return NO;
        }
    }

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
    } else if (menuItem == self.checkForUpdatesMenuItem) {
        return [self.updater validateMenuItem:menuItem];
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

- (void)_htk_main_updateStatusItemVisible
{
    if (!self.finishedLaunching) {
        return;
    }

    self.statusItem.visible = self.statusBarIconVisible;
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
    statusItem.behavior = NSStatusItemBehaviorRemovalAllowed;

    // `statusItem.visible` is automatically persistent in user default by `NSStatusItem`.
    self.statusBarIconVisible = statusItem.visible;
    // Neither key-value observer nor observable are retained. Should remove the observer on its `dealloc`.
    [statusItem addObserver:self forKeyPath:kStatusItemVisibleKeyPath options:0 context:(void *)&kStatusItemVisibleKeyObservingTag];

    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    statusItem.image = statusItemImage;

    NSMenu * const statusMenu = [[NSMenu alloc] init];

    NSMutableSet<NSMenuItem *> * const feedbackPreferencesMenuItemSet = [[NSMutableSet alloc] init];

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

    NSMenuItem * const feedbackSectionTitleMenuItem = [[NSMenuItem alloc] init];
    feedbackSectionTitleMenuItem.enabled = NO;
    feedbackSectionTitleMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_FEEDBACK_SECTION_TITLE_MENU_ITEM", @"A status menu item for feedback section title.");
    [statusMenu addItem:feedbackSectionTitleMenuItem];

    NSMenuItem * const noFeedbackMenuItem = [[NSMenuItem alloc] init];
    noFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_NO_FEEDBACK_MENU_ITEM", @"A status menu item to not use feedback.");
    noFeedbackMenuItem.keyEquivalent = @"0";
    noFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    noFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    noFeedbackMenuItem.target = self;
    [statusMenu addItem:noFeedbackMenuItem];
    [feedbackPreferencesMenuItemSet addObject:noFeedbackMenuItem];
    self.noFeedbackMenuItem = noFeedbackMenuItem;

    NSMenuItem * const useWeekFeedbackMenuItem = [[NSMenuItem alloc] init];
    useWeekFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_WEEK_FEEDBACK_MENU_ITEM", @"A status menu item to use weak feedback.");
    useWeekFeedbackMenuItem.keyEquivalent = @"1";
    useWeekFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useWeekFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useWeekFeedbackMenuItem.target = self;
    [statusMenu addItem:useWeekFeedbackMenuItem];
    [feedbackPreferencesMenuItemSet addObject:useWeekFeedbackMenuItem];
    self.useWeekFeedbackMenuItem = useWeekFeedbackMenuItem;

    NSMenuItem * const useMediumFeedbackMenuItem = [[NSMenuItem alloc] init];
    useMediumFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_MEDIUM_FEEDBACK_MENU_ITEM", @"A status menu item to use medium feedback.");
    useMediumFeedbackMenuItem.keyEquivalent = @"2";
    useMediumFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useMediumFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useMediumFeedbackMenuItem.target = self;
    [statusMenu addItem:useMediumFeedbackMenuItem];
    [feedbackPreferencesMenuItemSet addObject:useMediumFeedbackMenuItem];
    self.useMediumFeedbackMenuItem = useMediumFeedbackMenuItem;

    NSMenuItem * const useStrongFeedbackMenuItem = [[NSMenuItem alloc] init];
    useStrongFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_STRONG_FEEDBACK_MENU_ITEM", @"A status menu item to use strong feedback.");
    useStrongFeedbackMenuItem.keyEquivalent = @"3";
    useStrongFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useStrongFeedbackMenuItem.action = @selector(_htk_action_didSelectFeedbackTypeMenuItem:);
    useStrongFeedbackMenuItem.target = self;
    [statusMenu addItem:useStrongFeedbackMenuItem];
    [feedbackPreferencesMenuItemSet addObject:useStrongFeedbackMenuItem];
    self.useStrongFeedbackMenuItem = useStrongFeedbackMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const useSoundEffectMenuItem = [[NSMenuItem alloc] init];
    useSoundEffectMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SOUND_EFFECT_MENU_ITEM", @"A status menu item to use sound effect.");
    useSoundEffectMenuItem.action = @selector(_htk_action_didSelectSoundEffectTypeMenuItem:);
    useSoundEffectMenuItem.target = self;
    [statusMenu addItem:useSoundEffectMenuItem];
    [feedbackPreferencesMenuItemSet addObject:useSoundEffectMenuItem];
    self.useSoundEffectMenuItem = useSoundEffectMenuItem;

    NSMenuItem * const useScreenFlashMenuItem = [[NSMenuItem alloc] init];
    useScreenFlashMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SCREEN_FLASH_MENU_ITEM", @"A status menu item to use screen flash.");
    useScreenFlashMenuItem.action = @selector(_htk_action_didSelectScreenFlashMenuItem:);
    useScreenFlashMenuItem.target = self;
    [statusMenu addItem:useScreenFlashMenuItem];
    [feedbackPreferencesMenuItemSet addObject:useScreenFlashMenuItem];
    self.useScreenFlashMenuItem = useScreenFlashMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const checkForUpdatesMenuItem = [[NSMenuItem alloc] init];
    checkForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to check for updates.");
    checkForUpdatesMenuItem.action = @selector(_htk_action_didSelectCheckForUpdates:);
    checkForUpdatesMenuItem.target = self;
    [statusMenu addItem:checkForUpdatesMenuItem];
    self.checkForUpdatesMenuItem = checkForUpdatesMenuItem;

    NSMenuItem * const automaticallyCheckForUpdatesMenuItem = [[NSMenuItem alloc] init];
    automaticallyCheckForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_AUTOMATICALLY_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to set automatically check for updates.");
    automaticallyCheckForUpdatesMenuItem.action = @selector(_htk_action_didSelectAutomaticallyCheckForUpdateMenuItem:);
    automaticallyCheckForUpdatesMenuItem.target = self;
    [statusMenu addItem:automaticallyCheckForUpdatesMenuItem];
    self.automaticallyCheckForUpdatesMenuItem = automaticallyCheckForUpdatesMenuItem;

    [statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const startOnLoginMenuItem = [[NSMenuItem alloc] init];
    startOnLoginMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_START_ON_LOGIN_MENU_ITEM", @"A status menu item to start application on login.");
    startOnLoginMenuItem.action = @selector(_htk_action_didSelectStartOnLoginMenuItem:);
    startOnLoginMenuItem.target = self;
    [statusMenu addItem:startOnLoginMenuItem];
    self.startOnLoginMenuItem = startOnLoginMenuItem;

    NSMenuItem * const showStatusBarIconMenuItem = [[NSMenuItem alloc] init];
    showStatusBarIconMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SHOW_STATUS_BAR_ICON_MENU_ITEM", @"A status menu item to show icon in menu bar.");
    showStatusBarIconMenuItem.action = @selector(_htk_action_didSelectShowStatusBarIconMenuItem:);
    showStatusBarIconMenuItem.target = self;
    [statusMenu addItem:showStatusBarIconMenuItem];
    self.showStatusBarIconMenuItem = showStatusBarIconMenuItem;

    NSMenuItem * const aboutMenuItem = [[NSMenuItem alloc] init];
    aboutMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_ABOUT_MENU_ITEM", @"A status menu item to present a window about the application.");
    aboutMenuItem.action = @selector(_htk_action_didSelectAboutMenuItem:);
    [statusMenu addItem:aboutMenuItem];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_QUIT_MENU_ITEM", @"A status menu item to terminate the application.");
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    statusItem.menu = statusMenu;

    self.statusItem = statusItem;
    self.feedbackPreferencesMenuItemSet = feedbackPreferencesMenuItemSet;
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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    // This callback delegete methods is called when Finder reactivates an already running
    // application by `rapp` AppleEvent.

    // In case if the user previously hid the status bar icon, restore it.
    self.statusBarIconVisible = YES;

    return YES;
}

// MARK: - NSObject (NSKeyValueObserving)

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    if ([keyPath isEqualToString:kStatusItemVisibleKeyPath] && object == self.statusItem) {
        // Somehow, Key-Value observing calls observer method twice for the same change.
        self.statusBarIconVisible = self.statusItem.visible;
    }
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

- (void)_htk_action_didSelectCheckForUpdates:(id)sender
{
    // `checkForUpdates:` _MAY_ present `NSAlert` by calling `runModal`.
    // However, at this moment `NSMenu` is still appearing and if we use `runModal`,
    // AppKit seems begin in unexpected state and eventually crashes the app.
    // To workaround this behavior, simply perform the selector in later run loop in default mode.
    [self.updater performSelectorOnMainThread:@selector(checkForUpdates:) withObject:nil waitUntilDone:NO];
}

- (void)_htk_action_didSelectAutomaticallyCheckForUpdateMenuItem:(id)sender
{
    self.automaticallyCheckForUpdatesEnabled = !self.automaticallyCheckForUpdatesEnabled;
}

- (void)_htk_action_didSelectStartOnLoginMenuItem:(id)sender
{
    self.loginItemEnabled = !self.loginItemEnabled;
}

- (void)_htk_action_didSelectShowStatusBarIconMenuItem:(id)sender
{
    self.statusBarIconVisible = !self.statusBarIconVisible;
}

- (void)_htk_action_didSelectAboutMenuItem:(id)sender
{
    if ([NSApp activationPolicy] == NSApplicationActivationPolicyAccessory) {
        [NSApp activateIgnoringOtherApps:YES];
    }

    [NSApp orderFrontStandardAboutPanel:sender];
}

@end

NS_ASSUME_NONNULL_END
