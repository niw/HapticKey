//
//  HTKSounds.h
//  HapticKey
//
//  Created by Chris Ballinger on 1/30/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class helps manage the custom sound files available for playback.
 */
@interface HTKSounds : NSObject

// MARK: Properties

/** Current sound file directory */
@property (nonatomic, readonly) NSString *path;
/** Full paths to all potential sound files in this directory */
@property (nonatomic, readonly) NSArray<NSURL*> *allSoundFiles;

// MARK: Init

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/** Path to directory containing playable sound files. Will be created if directory doesn't exist. */
- (nullable instancetype)initWithPath:(NSString *)path error:(NSError**)error NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithDefaultPath;

// MARK: Public Methods

/** Reloads fingerUp and fingerDown players from user preferences */
- (void) reloadPlayers;

/** Play sound for finger up, if enabled */
- (void) playFingerUp;
/** Play sound for finger down, if enabled */
- (void) playFingerDown;

/** Resets to use default sounds */
- (BOOL) resetDefaultSounds;

// MARK: Class Properties

/** ~/Library/Application Support/HapticKey/Sounds/ */
@property (nonatomic, class, readonly) NSString *defaultPath;

@end

// MARK: - User Defaults

@interface HTKSounds (UserDefaults)

/** finger down sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerUpFilePath;
/** finger up sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerDownFilePath;

@end

NS_ASSUME_NONNULL_END
