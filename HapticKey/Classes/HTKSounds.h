//
//  HTKSounds.h
//  HapticKey
//
//  Created by Chris Ballinger on 1/30/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class helps manage the custom sound files available for playback.
 */
@interface HTKSounds : NSObject

/** Current sound file directory */
@property (nonatomic, readonly) NSString *path;
/** Full paths to all potential sound files in this directory */
@property (nonatomic, readonly) NSArray<NSURL*> *allSoundFiles;

@property (nonatomic, readonly, nullable) AVAudioPlayer *fingerUp;
@property (nonatomic, readonly, nullable) AVAudioPlayer *fingerDown;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/** Path to directory containing playable sound files. Will be created if directory doesn't exist. */
- (nullable instancetype)initWithPath:(NSString *)path error:(NSError**)error NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithDefaultPath;

/** Reloads fingerUp and fingerDown players */
- (void) reloadPlayers;

// MARK: - Class Properties

/** ~/Library/Application Support/HapticKey/Sounds/ */
@property (nonatomic, class, readonly) NSString *defaultPath;

/** finger down sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerUpFilePath;
/** finger up sound file path stored in user defaults */
@property (nonatomic, class, nullable) NSString *fingerDownFilePath;

@end

NS_ASSUME_NONNULL_END
