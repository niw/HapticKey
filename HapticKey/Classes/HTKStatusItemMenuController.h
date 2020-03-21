//
//  HTKStatusItemMenuController.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 3/21/20.
//  Copyright © 2020 Yoshimasa Niwa. All rights reserved.
//

@import AppKit;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class HTKStatusItemMenuController;

typedef NS_ENUM(NSInteger, HTKStatusItemMenuControllerMenuItem) {
    HTKStatusItemMenuControllerMenuItemUnknown = 0,

    HTKStatusItemMenuControllerMenuItemDisabled,
    HTKStatusItemMenuControllerMenuItemUseFunctionKeyEvent,
    HTKStatusItemMenuControllerMenuItemUseTapGestureEvent,

    HTKStatusItemMenuControllerMenuItemNoFeedback,
    HTKStatusItemMenuControllerMenuItemUseWeekFeedback,
    HTKStatusItemMenuControllerMenuItemUseMediumFeedback,
    HTKStatusItemMenuControllerMenuItemUseStrongFeedback,

    HTKStatusItemMenuControllerMenuItemUseSoundEffect,
    HTKStatusItemMenuControllerMenuItemUseScreenFlash,

    HTKStatusItemMenuControllerMenuItemCheckForUpdates,
    HTKStatusItemMenuControllerMenuItemAutomaticallyCheckForUpdates,

    HTKStatusItemMenuControllerMenuItemStartOnLogin,
    HTKStatusItemMenuControllerMenuItemShowStatusBarIcon,
    HTKStatusItemMenuControllerMenuItemAbout,
    HTKStatusItemMenuControllerMenuItemQuit
};

@protocol HTKStatusItemMenuControllerDelegate <NSObject>

@optional
- (BOOL)statusItemMenuController:(HTKStatusItemMenuController *)statusItemMenuController validateMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem;
- (void)statusItemMenuController:(HTKStatusItemMenuController *)statusItemMenuController didSelectMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem;

@end

@interface HTKStatusItemMenuController : NSObject

@property (nonatomic, weak, nullable) id<HTKStatusItemMenuControllerDelegate> delegate;
@property (nonatomic, readonly) NSMenu *menu;

- (void)setStateValue:(NSControlStateValue)stateValue forMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem;
- (NSControlStateValue)stateValueForMenuItem:(HTKStatusItemMenuControllerMenuItem)menuItem;

@end

NS_ASSUME_NONNULL_END
