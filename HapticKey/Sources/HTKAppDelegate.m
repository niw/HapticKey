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
#import "HTKStatusItemMenuController.h"
#import "HTKTapGestureEventListener.h"

@import Sparkle;

NS_ASSUME_NONNULL_BEGIN

static NSString * const kListeningEventTypeUserDefaultsKey = @"ListeningEventType";

// Each value is serialized in user defaults, _MUST NOT_ be changed.
typedef NS_ENUM(NSUInteger, HTKAppDelegateListeningEventType) {
    HTKAppDelegateListeningEventTypeNone = 0,
    HTKAppDelegateListeningEventTypeTouchBarFunctionKey = 1,
    HTKAppDelegateListeningEventTypeTapGesture = 2,
    // NOTE: This is for development only and not available in user interface.
    HTKAppDelegateListeningEventTypeAnyFunctionKey = 3,
};

static NSString * const kFeedbackTypeUserDefaultsKey = @"FeedbackType";

// Each value is serialized in user defaults, _MUST NOT_ be changed.
typedef NS_ENUM(NSUInteger, HTKAppDelegateFeedbackType) {
    HTKAppDelegateFeedbackTypeWeak = 0,
    HTKAppDelegateFeedbackTypeMedium = 1,
    HTKAppDelegateFeedbackTypeStrong = 2,
    // NOTE: Due to backward compatibility, this enum value is intentionally not zero.
    HTKAppDelegateFeedbackTypeNone = 3
};

static NSString * const kSoundEffectTypeUserDefaultsKey = @"SoundEffectType";

// Each value is serialized in user defaults, _MUST NOT_ be changed.
typedef NS_ENUM(NSUInteger, HTKAppDelegateSoundEffectType) {
    HTKAppDelegateSoundEffectTypeNone = 0,
    HTKAppDelegateSoundEffectTypeDefault = 1
};

// There was `SoundEffectVolume` with a default value `0.0`, which mute sound effects always
// and no way to make it enable again without using `defaults` command.
// To workaround the bug, the user defaults key name is changed.
static NSString * const kSoundEffectVolumeDefaultsKey = @"SoundEffectPlayerVolume";

static NSString * const kScreenFlashEnabledUserDefaultsKey = @"ScreenFlashEnabled";

static const char kStatusItemVisibleKeyObservingTag;
static NSString * const kStatusItemVisibleKeyPath = @"visible";

@interface HTKAppDelegate () <NSApplicationDelegate, HTKLoginItemDelegate, HTKStatusItemMenuControllerDelegate>

@property (nonatomic, readonly) SUUpdater *updater;

@property (nonatomic, getter=isFinishedLaunching) BOOL finishedLaunching;

@property (nonatomic) HTKAppDelegateListeningEventType listeningEventType;
@property (nonatomic) HTKAppDelegateFeedbackType feedbackType;
@property (nonatomic) HTKAppDelegateSoundEffectType soundEffectType;
@property (nonatomic) float soundEffectVolume;
@property (nonatomic, getter=isScreenFlashEnabled) BOOL screenFlashEnabled;
@property (nonatomic, getter=isLoginItemEnabled) BOOL loginItemEnabled;
@property (nonatomic, getter=isAutomaticallyCheckForUpdatesEnabled) BOOL automaticallyCheckForUpdatesEnabled;
@property (nonatomic, getter=isStatusBarIconVisible) BOOL statusBarIconVisible;

@property (nonatomic, nullable) HTKHapticFeedback *hapticFeedback;
@property (nonatomic, nullable) HTKLoginItem *mainBundleLoginItem;

@property (nonatomic, nullable) NSStatusItem *statusItem;
// See `observeValueForKeyPath:ofObject:change:context:`.
@property (nonatomic) BOOL lastStatusItemVisible;

@property (nonatomic, nullable) HTKStatusItemMenuController *statusItemMenuController;

@end

@implementation HTKAppDelegate

- (instancetype)init
{
    if (self = [super init]) {
        _updater = [[SUUpdater alloc] init];
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

- (void)setSoundEffectVolume:(float)soundEffectVolume
{
    if (_soundEffectVolume != soundEffectVolume) {
        _soundEffectVolume = soundEffectVolume;

        [self _htk_main_updateSoundFeedbackVolume];

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
    alert.messageText = NSLocalizedString(@"ALERT_HIDING_STATUS_BAR_ICON_MESSAGE_TEXT", @"A title text for warning about hiding icon in menu bar.");
    alert.informativeText = NSLocalizedString(@"ALERT_HIDING_STATUS_BAR_ICON_INFORMATIVE_TEXT", @"A body text for warning about hiding icon in menu bar.");

    // Workaround to avoid potential application crash.
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

    [self.statusItemMenuController setStateValue:(self.listeningEventType == HTKAppDelegateListeningEventTypeNone) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemDisabled];
    [self.statusItemMenuController setStateValue:(self.listeningEventType == HTKAppDelegateListeningEventTypeTouchBarFunctionKey) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseFunctionKeyEvent];
    [self.statusItemMenuController setStateValue:(self.listeningEventType == HTKAppDelegateListeningEventTypeTapGesture) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseTapGestureEvent];

    [self.statusItemMenuController setStateValue:(!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeNone) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemNoFeedback];
    [self.statusItemMenuController setStateValue:(!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeWeak) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseWeekFeedback];
    [self.statusItemMenuController setStateValue:(!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeMedium) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseMediumFeedback];
    [self.statusItemMenuController setStateValue:(!disabled && self.feedbackType == HTKAppDelegateFeedbackTypeStrong) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseStrongFeedback];

    [self.statusItemMenuController setStateValue:(!disabled && self.soundEffectType == HTKAppDelegateSoundEffectTypeDefault) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseSoundEffect];
    [self.statusItemMenuController setStateValue:(!disabled && self.screenFlashEnabled) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemUseScreenFlash];

    [self.statusItemMenuController setStateValue:(self.automaticallyCheckForUpdatesEnabled) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemAutomaticallyCheckForUpdates];

    [self.statusItemMenuController setStateValue:(self.loginItemEnabled) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemStartOnLogin];
    [self.statusItemMenuController setStateValue:(self.statusBarIconVisible) ? NSControlStateValueOn : NSControlStateValueOff forMenuItem:HTKStatusItemMenuControllerMenuItemShowStatusBarIcon];

    self.statusItem.visible = self.statusBarIconVisible;
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
        case HTKAppDelegateListeningEventTypeTouchBarFunctionKey:
            eventListener = [[HTKFunctionKeyEventListener alloc] initWithKeyboardType:HTKFunctionKeyEventListenerKeyboardTypeTouchBar];
            break;
        case HTKAppDelegateListeningEventTypeTapGesture:
            eventListener = [[HTKTapGestureEventListener alloc] init];
            break;
        case HTKAppDelegateListeningEventTypeAnyFunctionKey:
            eventListener = [[HTKFunctionKeyEventListener alloc] initWithKeyboardType:HTKFunctionKeyEventListenerKeyboardTypeAny];
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
    [self _htk_main_updateSoundFeedbackVolume];
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

- (void)_htk_main_updateSoundFeedbackVolume
{
    if (!self.hapticFeedback) {
        return;
    }

    self.hapticFeedback.soundVolume = self.soundEffectVolume;
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
    [defaults setFloat:self.soundEffectVolume forKey:kSoundEffectVolumeDefaultsKey];
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
        listeningEventType = HTKAppDelegateListeningEventTypeTouchBarFunctionKey;
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

    float soundEffectVolume;
    if ([defaults objectForKey:kSoundEffectVolumeDefaultsKey]) {
        soundEffectVolume = [defaults floatForKey:kSoundEffectVolumeDefaultsKey];
    } else {
        soundEffectVolume = 1.0;
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
    self.soundEffectVolume = soundEffectVolume;
    self.screenFlashEnabled = screenFlashEnabled;
}

- (void)_htk_main_loadStatusItem
{
    NSStatusBar * const statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem * const statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    // NOTE: This `highlightsBy` that is alternative to the deprecated
    // `statusItem.highlightMode = YES` may be not necessary anymore.
    NSButtonCell * const statusItemButtonCell = (NSButtonCell *)statusItem.button.cell;
    statusItemButtonCell.highlightsBy = NSContentsCellMask | NSChangeBackgroundCellMask;
    statusItem.behavior = NSStatusItemBehaviorRemovalAllowed;

    // `statusItem.visible` is automatically persistent in user default by `NSStatusItem`.
    self.statusBarIconVisible = statusItem.visible;
    // Neither key-value observer nor observable are retained. Should remove the observer on its `dealloc`.
    [statusItem addObserver:self forKeyPath:kStatusItemVisibleKeyPath options:0 context:(void *)&kStatusItemVisibleKeyObservingTag];

    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    statusItem.button.image = statusItemImage;

    HTKStatusItemMenuController * const statusItemMenuController = [[HTKStatusItemMenuController alloc] init];
    statusItemMenuController.delegate = self;
    self.statusItemMenuController = statusItemMenuController;

    statusItem.menu = statusItemMenuController.menu;

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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    // This callback delegate methods is called when Finder reactivates an already running
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

// MARK: - HTKStatusItemMenuControllerDelegate

- (BOOL)statusItemMenuController:(HTKStatusItemMenuController *)statusItemMenuController validateMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem
{
    // Disable any menu items for configuration when no events are listened.
    switch (menuItem) {
        case HTKStatusItemMenuControllerMenuItemNoFeedback:
        case HTKStatusItemMenuControllerMenuItemUseWeekFeedback:
        case HTKStatusItemMenuControllerMenuItemUseMediumFeedback:
        case HTKStatusItemMenuControllerMenuItemUseStrongFeedback:
        case HTKStatusItemMenuControllerMenuItemUseSoundEffect:
        case HTKStatusItemMenuControllerMenuItemUseScreenFlash:
            if (self.listeningEventType == HTKAppDelegateListeningEventTypeNone) {
                return NO;
            }
            break;
        default:
            break;
    }

    // Do not allow to have a combination of settings that has no feedback effects.
    // This is a loose guard at user interface level and not really preventing to have such condition.
    switch (menuItem) {
        case HTKStatusItemMenuControllerMenuItemNoFeedback:
            if ((self.soundEffectType == HTKAppDelegateSoundEffectTypeNone) && !self.screenFlashEnabled) {
                return (self.feedbackType == HTKAppDelegateFeedbackTypeNone);
            }
            break;
        case HTKStatusItemMenuControllerMenuItemUseSoundEffect:
            if (self.feedbackType == HTKAppDelegateFeedbackTypeNone && !self.screenFlashEnabled) {
                return (self.soundEffectType == HTKAppDelegateSoundEffectTypeNone);
            }
            break;
        case HTKStatusItemMenuControllerMenuItemUseScreenFlash:
            if ((self.feedbackType == HTKAppDelegateFeedbackTypeNone) && (self.soundEffectType == HTKAppDelegateSoundEffectTypeNone)) {
                return !self.screenFlashEnabled;
            }
            break;
        default:
            break;
    }

    switch (menuItem) {
        case HTKStatusItemMenuControllerMenuItemCheckForUpdates: {
            // `-[SUUpdater validateMenuItem:]` takes valid `NSMenuItem` and checks its `action`
            // for the validation result.
            NSMenuItem * const checkForUpdateMenuItem = [[NSMenuItem alloc] init];
            checkForUpdateMenuItem.action = @selector(checkForUpdates:);
            return [self.updater validateMenuItem:checkForUpdateMenuItem];
            break;
        }
        default:
            break;
    }

    return YES;
}

static NSString * const kBuildTimestampInfoPlistKey = @"HTKBuildTimestamp";
static NSString * const kBuildGitSHAInfoPlistKey = @"HTKBuildGitSHA";

static NSDictionary * const AboutPanelOptions(void)
{
    NSMutableDictionary * const options = [[NSMutableDictionary alloc] init];
    if (@available(macOS 10.13, *)) {
        NSBundle * const mainBundle = NSBundle.mainBundle;

        id const bundleVersion = [mainBundle objectForInfoDictionaryKey:(__bridge id)kCFBundleVersionKey];

        id const bundleBuildTimestamp = [mainBundle objectForInfoDictionaryKey:kBuildTimestampInfoPlistKey];
        NSString *displayBuildTimestampString;
        if ([bundleBuildTimestamp isKindOfClass:NSString.class]) {
            NSString * const bundleBuildTimestampString = (NSString *)bundleBuildTimestamp;

            NSISO8601DateFormatter * const buildTimestampStringDateFormatter = [[NSISO8601DateFormatter alloc] init];
            NSDate * const buildDate = [buildTimestampStringDateFormatter dateFromString:bundleBuildTimestampString];
            if (buildDate) {
                NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateStyle = NSDateFormatterMediumStyle;
                dateFormatter.timeStyle = NSDateFormatterShortStyle;
                displayBuildTimestampString = [dateFormatter stringFromDate:buildDate];
            }
        }

        id const bundleBuildGitSHA = [mainBundle objectForInfoDictionaryKey:kBuildGitSHAInfoPlistKey];
        NSString *displayBuildGitSHAString;
        if ([bundleBuildGitSHA isKindOfClass:NSString.class]) {
            NSString * const bundleBuildGitSHAString = (NSString *)bundleBuildGitSHA;

            if (bundleBuildGitSHAString.length > 7) {
                displayBuildGitSHAString = [bundleBuildGitSHAString substringWithRange:NSMakeRange(0, 7)];
            } else {
                displayBuildGitSHAString = bundleBuildGitSHAString;
            }
        }

        NSString * const versionString = [[NSString alloc] initWithFormat:@"%@, %@, %@", bundleVersion, displayBuildTimestampString, displayBuildGitSHAString];
        options[NSAboutPanelOptionVersion] = versionString;
    }
    return [options copy];
}

- (void)statusItemMenuController:(HTKStatusItemMenuController *)statusItemMenuController didSelectMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem
{
    switch (menuItem) {
        case HTKStatusItemMenuControllerMenuItemUnknown:
            break;

        case HTKStatusItemMenuControllerMenuItemDisabled:
            self.listeningEventType = HTKAppDelegateListeningEventTypeNone;
            break;
        case HTKStatusItemMenuControllerMenuItemUseFunctionKeyEvent:
            self.listeningEventType = HTKAppDelegateListeningEventTypeTouchBarFunctionKey;
            break;
        case HTKStatusItemMenuControllerMenuItemUseTapGestureEvent:
            self.listeningEventType = HTKAppDelegateListeningEventTypeTapGesture;
            break;

        case HTKStatusItemMenuControllerMenuItemNoFeedback:
            self.feedbackType = HTKAppDelegateFeedbackTypeNone;
            break;
        case HTKStatusItemMenuControllerMenuItemUseWeekFeedback:
            self.feedbackType = HTKAppDelegateFeedbackTypeWeak;
            break;
        case HTKStatusItemMenuControllerMenuItemUseMediumFeedback:
            self.feedbackType = HTKAppDelegateFeedbackTypeMedium;
            break;
        case HTKStatusItemMenuControllerMenuItemUseStrongFeedback:
            self.feedbackType = HTKAppDelegateFeedbackTypeStrong;
            break;

        case HTKStatusItemMenuControllerMenuItemUseSoundEffect:
            // For now, there is one sound effect and the menu item works as a boolean.
            switch (self.soundEffectType) {
                case HTKAppDelegateSoundEffectTypeNone:
                    self.soundEffectType = HTKAppDelegateSoundEffectTypeDefault;
                    break;
                case HTKAppDelegateSoundEffectTypeDefault:
                    self.soundEffectType = HTKAppDelegateSoundEffectTypeNone;
                    break;
            }
            break;
        case HTKStatusItemMenuControllerMenuItemUseScreenFlash:
            self.screenFlashEnabled = !self.screenFlashEnabled;
            break;

        case HTKStatusItemMenuControllerMenuItemCheckForUpdates:
            [self.updater checkForUpdates:nil];
            break;
        case HTKStatusItemMenuControllerMenuItemAutomaticallyCheckForUpdates:
            self.automaticallyCheckForUpdatesEnabled = !self.automaticallyCheckForUpdatesEnabled;
            break;

        case HTKStatusItemMenuControllerMenuItemStartOnLogin:
            self.loginItemEnabled = !self.loginItemEnabled;
            break;
        case HTKStatusItemMenuControllerMenuItemShowStatusBarIcon:
            self.statusBarIconVisible = !self.statusBarIconVisible;
            break;
        case HTKStatusItemMenuControllerMenuItemAbout: {
            if ([NSApp activationPolicy] == NSApplicationActivationPolicyAccessory) {
                [NSApp activateIgnoringOtherApps:YES];
            }
            [NSApp orderFrontStandardAboutPanelWithOptions:AboutPanelOptions()];
            break;
        }
        case HTKStatusItemMenuControllerMenuItemQuit:
            [NSApp terminate:nil];
            break;
    }
}

@end

NS_ASSUME_NONNULL_END
