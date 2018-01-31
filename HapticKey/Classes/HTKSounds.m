//
//  HTKSounds.m
//  HapticKey
//
//  Created by Chris Ballinger on 1/30/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKSounds.h"

@import os.log;

NS_ASSUME_NONNULL_BEGIN

static NSString * const kDefaultSystemSoundFilePath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/ink/InkSoundBecomeMouse.aif";

static NSString * const kFingerUpFilePathKey = @"FingerUpFilePath";
static NSString * const kFingerDownFilePathKey = @"FingerDownFilePath";

@implementation HTKSounds

// MARK: - Init

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (nullable instancetype)initWithPath:(NSString *)path error:(NSError**)error
{
    NSParameterAssert(path);
    if (self = [super init]) {
        _path = [path copy];
        if (![self createDirectoryIfNeeded:error]) {
            return nil;
        }
        [self reloadPlayers];
    }
    return self;
}

- (nullable instancetype)initWithDefaultPath {
    return [self initWithPath:self.class.defaultPath error:nil];
}

- (void) reloadPlayers {
    _fingerUp = nil;
    _fingerDown = nil;
    NSError *error = nil;
    NSString *fingerUpFilePath = self.class.fingerUpFilePath;
    NSString *fingerDownFilePath = self.class.fingerDownFilePath;
    if (fingerUpFilePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:fingerUpFilePath];
        _fingerUp = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    }
    if (fingerDownFilePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:fingerUpFilePath];
        _fingerDown = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    }
}

- (NSArray<NSURL*>*) allSoundFiles {
    NSArray<NSURL*> *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.path] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    if (!contents.count) {
        // we must populate an initial sound
        [self populateDefaultSounds];
        contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.path] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    }
    return contents;
}

// MARK: - Private

- (BOOL) createDirectoryIfNeeded:(NSError**)error {
    // create directory if it isn't already
    BOOL isDirectory = NO;
    BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:_path isDirectory:&isDirectory];
    if (exists && !isDirectory) {
        // path must be a directory
        return NO;
    } else if (!exists) {
        return [NSFileManager.defaultManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:error];
    } else {
        return YES;
    }
}

- (BOOL) populateDefaultSounds {
    // we must populate an initial sound
    // TODO: use proper localized string
    NSString *fileName = [NSLocalizedString(@"Default", @"default audio file") stringByAppendingPathExtension:@"aif"];
    if (!fileName) {
        return NO;
    }
    NSString *newPath = [self.path stringByAppendingPathComponent:fileName];
    BOOL result = [NSFileManager.defaultManager copyItemAtPath:kDefaultSystemSoundFilePath toPath:newPath error:nil];
    if (!result) {
        os_log_error(OS_LOG_DEFAULT, "Fail to create default system sound at path: %{public}@", newPath);
        return NO;
    }
    return YES;
}

// MARK: - Class Properties

+ (NSString*) defaultPath {
    NSString *applicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).lastObject;
    NSString *applicationName = NSBundle.mainBundle.infoDictionary[(NSString*)kCFBundleNameKey];
    NSString *appDirectory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    NSString *soundsDirectory = [appDirectory stringByAppendingPathComponent:@"Sounds"];
    NSParameterAssert(soundsDirectory);
    return soundsDirectory;
}

+ (void) setFingerUpFilePath:(nullable NSString *)fingerUpFilePath {
    if (fingerUpFilePath) {
        [NSUserDefaults.standardUserDefaults setObject:fingerUpFilePath forKey:kFingerUpFilePathKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kFingerUpFilePathKey];
    }
}

+ (nullable NSString*) fingerUpFilePath {
    return [NSUserDefaults.standardUserDefaults stringForKey:kFingerUpFilePathKey];
}

+ (void) setFingerDownFilePath:(nullable NSString *)fingerDownFilePath {
    if (fingerDownFilePath) {
        [NSUserDefaults.standardUserDefaults setObject:fingerDownFilePath forKey:kFingerDownFilePathKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kFingerDownFilePathKey];
    }
}

+ (nullable NSString*) fingerDownFilePath {
    return [NSUserDefaults.standardUserDefaults stringForKey:kFingerDownFilePathKey];
}

@end

NS_ASSUME_NONNULL_END
