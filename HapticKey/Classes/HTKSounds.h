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
- (void) reloadFingerUp;
- (void) reloadFingerDown;
/** Updates player volumes based on stored user preference */
- (void) updateVolume;

/** Play sound for finger up, if enabled */
- (void) playFingerUp;
/** Play sound for finger down, if enabled */
- (void) playFingerDown;

// MARK: Class Properties

@end

// MARK: - File Paths

@interface HTKSounds (FilePaths)

/** ~/Library/Application Support/HapticKey/Sounds/ */
@property (nonatomic, class, readonly) NSString *defaultSoundsDirectory;
/** Default sound for finger-up */
@property (nonatomic, class, readonly) NSString *defaultUpFilePath;
/** Default sound for finger-down */
@property (nonatomic, class, readonly) NSString *defaultDownFilePath;

@end

// MARK: - User Defaults

@interface HTKSounds (UserDefaults)

/** finger down sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerUpFilePath;
/** finger up sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerDownFilePath;

/** volume from 0.0 -> 1.0. Takes effect after reloadPlayers is called. */
@property (nonatomic, class) float desiredVolume;

/** Force-resets to use default sounds */
- (void) resetDefaultSounds;

@end

NS_ASSUME_NONNULL_END
