//
//  HTKSoundMenu.h
//  HapticKey
//
//  Created by Chris Ballinger on 2/2/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;
@import AppKit;

@class HTKSounds;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class helps create and manage the sound submenu.
 */
@interface HTKSoundMenu : NSObject

// MARK: Properties

@property (nonatomic, readonly) HTKSounds *sounds;
@property (nonatomic, readonly) NSMenu *soundSubmenu;

// MARK: Init

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSounds:(HTKSounds *)sounds NS_DESIGNATED_INITIALIZER;

// MARK: Public Methods

- (void) refreshMenuItems;

@end

NS_ASSUME_NONNULL_END
