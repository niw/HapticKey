//
//  HTKStatusItemMenuController.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 3/21/20.
//  Copyright © 2020 Yoshimasa Niwa. All rights reserved.
//

#import "HTKStatusItemMenuController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTKStatusItemMenuController () <NSMenuItemValidation>

@property (nonatomic, nullable) NSArray<NSMenuItem *> *menuItems;

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

@implementation HTKStatusItemMenuController

// MARK: - Properties

@synthesize menu = _menu;

- (NSMenu *)menu
{
    if (!_menu) {
        [self _htk_main_loadMenu];
    }
    return _menu;
}

- (void)_htk_main_loadMenu
{
    if (_menu) {
        return;
    }

    NSMenu * const menu = [[NSMenu alloc] init];

    NSMenuItem * const disabledMenuItem = [[NSMenuItem alloc] init];
    disabledMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_DISABLED_ITEM", @"A status menu item selected when it is disabled.");
    disabledMenuItem.tag = HTKStatusItemMenuControllerMenuItemDisabled;
    disabledMenuItem.action = @selector(_htk_main_didSelectMenuItem:);
    disabledMenuItem.target = self;
    [menu addItem:disabledMenuItem];
    self.disabledMenuItem = disabledMenuItem;

    NSMenuItem * const useFunctionKeyEventMenuItem = [[NSMenuItem alloc] init];
    useFunctionKeyEventMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_FUNCTION_KEY_EVENT_MENU_ITEM", @"A status menu item to use function key events.");
    useFunctionKeyEventMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseFunctionKeyEvent;
    useFunctionKeyEventMenuItem.action = @selector(_htk_main_didSelectMenuItem:);
    useFunctionKeyEventMenuItem.target = self;
    [menu addItem:useFunctionKeyEventMenuItem];
    self.useFunctionKeyEventMenuItem = useFunctionKeyEventMenuItem;

    NSMenuItem * const useTapGestureEventMenuItem = [[NSMenuItem alloc] init];
    useTapGestureEventMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_TAP_GESTURE_EVENT_MENU_ITEM", @"A status menu item to use tap gesture events.");
    useTapGestureEventMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseTapGestureEvent;
    useTapGestureEventMenuItem.action = @selector(_htk_main_didSelectMenuItem:);
    useTapGestureEventMenuItem.target = self;
    [menu addItem:useTapGestureEventMenuItem];
    self.useTapGestureEventMenuItem = useTapGestureEventMenuItem;

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const feedbackSectionTitleMenuItem = [[NSMenuItem alloc] init];
    feedbackSectionTitleMenuItem.enabled = NO;
    feedbackSectionTitleMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_FEEDBACK_SECTION_TITLE_MENU_ITEM", @"A status menu item for feedback section title.");
    [menu addItem:feedbackSectionTitleMenuItem];

    NSMenuItem * const noFeedbackMenuItem = [[NSMenuItem alloc] init];
    noFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_NO_FEEDBACK_MENU_ITEM", @"A status menu item to not use feedback.");
    noFeedbackMenuItem.tag = HTKStatusItemMenuControllerMenuItemNoFeedback;
    noFeedbackMenuItem.keyEquivalent = @"0";
    noFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    noFeedbackMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    noFeedbackMenuItem.target = self;
    [menu addItem:noFeedbackMenuItem];
    self.noFeedbackMenuItem = noFeedbackMenuItem;

    NSMenuItem * const useWeekFeedbackMenuItem = [[NSMenuItem alloc] init];
    useWeekFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_WEEK_FEEDBACK_MENU_ITEM", @"A status menu item to use weak feedback.");
    useWeekFeedbackMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseWeekFeedback;
    useWeekFeedbackMenuItem.keyEquivalent = @"1";
    useWeekFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useWeekFeedbackMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    useWeekFeedbackMenuItem.target = self;
    [menu addItem:useWeekFeedbackMenuItem];
    self.useWeekFeedbackMenuItem = useWeekFeedbackMenuItem;

    NSMenuItem * const useMediumFeedbackMenuItem = [[NSMenuItem alloc] init];
    useMediumFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_MEDIUM_FEEDBACK_MENU_ITEM", @"A status menu item to use medium feedback.");
    useMediumFeedbackMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseMediumFeedback;
    useMediumFeedbackMenuItem.keyEquivalent = @"2";
    useMediumFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useMediumFeedbackMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    useMediumFeedbackMenuItem.target = self;
    [menu addItem:useMediumFeedbackMenuItem];
    self.useMediumFeedbackMenuItem = useMediumFeedbackMenuItem;

    NSMenuItem * const useStrongFeedbackMenuItem = [[NSMenuItem alloc] init];
    useStrongFeedbackMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_STRONG_FEEDBACK_MENU_ITEM", @"A status menu item to use strong feedback.");
    useStrongFeedbackMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseStrongFeedback;
    useStrongFeedbackMenuItem.keyEquivalent = @"3";
    useStrongFeedbackMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    useStrongFeedbackMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    useStrongFeedbackMenuItem.target = self;
    [menu addItem:useStrongFeedbackMenuItem];
    self.useStrongFeedbackMenuItem = useStrongFeedbackMenuItem;

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const useSoundEffectMenuItem = [[NSMenuItem alloc] init];
    useSoundEffectMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SOUND_EFFECT_MENU_ITEM", @"A status menu item to use sound effect.");
    useSoundEffectMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseSoundEffect;
    useSoundEffectMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    useSoundEffectMenuItem.target = self;
    [menu addItem:useSoundEffectMenuItem];
    self.useSoundEffectMenuItem = useSoundEffectMenuItem;

    NSMenuItem * const useScreenFlashMenuItem = [[NSMenuItem alloc] init];
    useScreenFlashMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SCREEN_FLASH_MENU_ITEM", @"A status menu item to use screen flash.");
    useScreenFlashMenuItem.tag = HTKStatusItemMenuControllerMenuItemUseScreenFlash;
    useScreenFlashMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    useScreenFlashMenuItem.target = self;
    [menu addItem:useScreenFlashMenuItem];
    self.useScreenFlashMenuItem = useScreenFlashMenuItem;

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const checkForUpdatesMenuItem = [[NSMenuItem alloc] init];
    checkForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to check for updates.");
    checkForUpdatesMenuItem.tag = HTKStatusItemMenuControllerMenuItemCheckForUpdates;
    checkForUpdatesMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    checkForUpdatesMenuItem.target = self;
    [menu addItem:checkForUpdatesMenuItem];
    self.checkForUpdatesMenuItem = checkForUpdatesMenuItem;

    NSMenuItem * const automaticallyCheckForUpdatesMenuItem = [[NSMenuItem alloc] init];
    automaticallyCheckForUpdatesMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_AUTOMATICALLY_CHECK_FOR_UPDATES_MENU_ITEM", @"A status menu item to set automatically check for updates.");
    automaticallyCheckForUpdatesMenuItem.tag = HTKStatusItemMenuControllerMenuItemAutomaticallyCheckForUpdates;
    automaticallyCheckForUpdatesMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    automaticallyCheckForUpdatesMenuItem.target = self;
    [menu addItem:automaticallyCheckForUpdatesMenuItem];
    self.automaticallyCheckForUpdatesMenuItem = automaticallyCheckForUpdatesMenuItem;

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem * const startOnLoginMenuItem = [[NSMenuItem alloc] init];
    startOnLoginMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_START_ON_LOGIN_MENU_ITEM", @"A status menu item to start application on login.");
    startOnLoginMenuItem.tag = HTKStatusItemMenuControllerMenuItemStartOnLogin;
    startOnLoginMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    startOnLoginMenuItem.target = self;
    [menu addItem:startOnLoginMenuItem];
    self.startOnLoginMenuItem = startOnLoginMenuItem;

    NSMenuItem * const showStatusBarIconMenuItem = [[NSMenuItem alloc] init];
    showStatusBarIconMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_SHOW_STATUS_BAR_ICON_MENU_ITEM", @"A status menu item to show icon in menu bar.");
    showStatusBarIconMenuItem.tag = HTKStatusItemMenuControllerMenuItemShowStatusBarIcon;
    showStatusBarIconMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    showStatusBarIconMenuItem.target = self;
    [menu addItem:showStatusBarIconMenuItem];
    self.showStatusBarIconMenuItem = showStatusBarIconMenuItem;

    NSMenuItem * const aboutMenuItem = [[NSMenuItem alloc] init];
    aboutMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_ABOUT_MENU_ITEM", @"A status menu item to present a window about the application.");
    aboutMenuItem.tag = HTKStatusItemMenuControllerMenuItemAbout;
    aboutMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    aboutMenuItem.target = self;
    [menu addItem:aboutMenuItem];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = NSLocalizedString(@"STATUS_MENU_ITEM_QUIT_MENU_ITEM", @"A status menu item to terminate the application.");
    quitMenuItem.tag = HTKStatusItemMenuControllerMenuItemQuit;
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(_htk_action_didSelectMenuItem:);
    quitMenuItem.target = self;
    [menu addItem:quitMenuItem];

    _menu = menu;
}

- (void)setStateValue:(NSControlStateValue)stateValue forMenuItem:(HTKStatusItemMenuControllerMenuItem)tag
{
    if (tag == HTKStatusItemMenuControllerMenuItemUnknown) {
        return;
    }

    NSMenuItem * const menuItem = [self.menu itemWithTag:tag];
    menuItem.state = stateValue;
}

- (NSControlStateValue)stateValueForMenuItem:(HTKStatusItemMenuControllerMenuItem)tag
{
    if (tag == HTKStatusItemMenuControllerMenuItemUnknown) {
        return NSControlStateValueOff;
    }

    NSMenuItem * const menuItem = [self.menu itemWithTag:tag];
    return menuItem.state;
}

// MARK: - NSMenuItemValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    id<HTKStatusItemMenuControllerDelegate> const delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(statusItemMenuController:validateMenuItem:)]) {
        return [delegate statusItemMenuController:self validateMenuItem:menuItem.tag];
    }
    return YES;
}

// MARK: - Actions

- (void)_htk_action_didSelectMenuItem:(id)sender
{
    // At this moment `NSMenu` is still appearing and the main run loop is not in default mode.
    // If it is executing specific task such as presenting `NSAlert` with `runModel`,
    // AppKit seems begin in unexpected state and eventually crashes the app.
    // This is happening when it is calling `-[SUUpdater checkForUpdates:]`, or `-[NSApplication terminate:]`.
    // To workaround this behavior, simply perform the selector in later run loop in default mode.
    [self performSelectorOnMainThread:@selector(_htk_main_didSelectMenuItem:) withObject:sender waitUntilDone:NO];
}

- (void)_htk_main_didSelectMenuItem:(id)sender
{
    if (![sender respondsToSelector:@selector(tag)]) {
        return;
    }
    NSMenuItem * const menuItem = (NSMenuItem *)sender;

    id<HTKStatusItemMenuControllerDelegate> const delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(statusItemMenuController:didSelectMenuItem:)]) {
        [delegate statusItemMenuController:self didSelectMenuItem:menuItem.tag];
    }
}

@end

NS_ASSUME_NONNULL_END
