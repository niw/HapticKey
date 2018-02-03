//
//  HTKSounds.m
//  HapticKey
//
//  Created by Chris Ballinger on 1/30/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKSounds.h"

@import AudioToolbox;
@import os.log;
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN

static NSString * const kDefaultDownSoundFileName = @"↓.aif";
static NSString * const kDefaultUpSoundFileName = @"↑.aif";

static NSString * const kDefaultSystemSoundFilePath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/ink/InkSoundBecomeMouse.aif";
static UInt64 const kDefaultSystemSoundExpectedAudioBytes = 88032;

/** NSUserDefaults key */
static NSString * const kFingerUpFilePathKey = @"FingerUpFilePath";
/** NSUserDefaults key */
static NSString * const kFingerDownFilePathKey = @"FingerDownFilePath";
static NSString * const kDesiredVolumeKey = @"DesiredVolume";


@interface HTKSounds() <AVAudioPlayerDelegate>
@property (nonatomic, readonly, nullable) AVAudioPlayer *fingerUp;
@property (nonatomic, readonly, nullable) AVAudioPlayer *fingerDown;
@end

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
        if (![self createSoundsDirectoryIfNeeded:error]) {
            return nil;
        }
        [self createDefaultSoundsIfNeeded];
        [self checkValidityOfUserSoundPreferences];
        [self reloadPlayers];
    }
    return self;
}

- (nullable instancetype)initWithDefaultPath {
    return [self initWithPath:self.class.defaultSoundsDirectory error:nil];
}

// MARK: - Public

- (void) playFingerUp {
    [self.fingerUp play];
}

- (void) playFingerDown {
    [self.fingerDown play];
}

- (void) reloadPlayers {
    [self reloadFingerDown];
    [self reloadFingerUp];
}

- (void) reloadFingerUp {
    _fingerUp = nil;
    NSString *fingerUpFilePath = self.class.fingerUpFilePath;
    if (fingerUpFilePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:fingerUpFilePath];
        _fingerUp = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    }
    _fingerUp.volume = self.class.desiredVolume;
}

- (void) reloadFingerDown {
    _fingerDown = nil;
    NSString *fingerDownFilePath = self.class.fingerDownFilePath;
    if (fingerDownFilePath) {
        NSURL *fileURL = [NSURL fileURLWithPath:fingerDownFilePath];
        _fingerDown = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    }
    _fingerDown.volume = self.class.desiredVolume;
}

- (void) updateVolume {
    _fingerUp.volume = self.class.desiredVolume;
    _fingerDown.volume = self.class.desiredVolume;
}

- (NSArray<NSURL*>*) allSoundFiles {
    NSArray<NSURL*> *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.path] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    if (!contents.count) {
        // we must populate an initial sound
        [self resetDefaultSounds];
        contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.path] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    }
    return contents;
}

// MARK: - Private

/// checks if user's sound preferences point to valid paths
/// and unsets them if they are invalid
- (void) checkValidityOfUserSoundPreferences {
    if (![NSFileManager.defaultManager fileExistsAtPath:self.class.fingerUpFilePath]) {
        self.class.fingerUpFilePath = nil;
    }
    if (![NSFileManager.defaultManager fileExistsAtPath:self.class.fingerDownFilePath]) {
        self.class.fingerDownFilePath = nil;
    }
}

/// creates destination sound directory if it is not present
- (BOOL) createSoundsDirectoryIfNeeded:(NSError**)error {
    BOOL isDirectory = NO;
    BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:self.path isDirectory:&isDirectory];
    if (exists && !isDirectory) {
        // path must be a directory
        return NO;
    } else if (!exists) {
        return [NSFileManager.defaultManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:error];
    } else {
        return YES;
    }
}

/// on first launch, split the default system sound into two
/// separate sound files for finger-up and finger-down
/// returns YES if sounds are ready, or NO on failure
- (BOOL) createDefaultSoundsIfNeeded {
    // bail out if we've got the files already
    if ([NSFileManager.defaultManager fileExistsAtPath:self.class.defaultUpFilePath] &&
        [NSFileManager.defaultManager fileExistsAtPath:self.class.defaultDownFilePath]) {
        return YES;
    } else {
        return [self createDefaultSoundFiles];
    }
}

/// creates default up/down sound files from source system sound
- (BOOL) createDefaultSoundFiles {
    NSURL *originalFile = [NSURL fileURLWithPath:kDefaultSystemSoundFilePath];
    
    AudioFileID inAudioFile = NULL;
    AudioFileID downFile = NULL;
    AudioFileID upFile = NULL;
    dispatch_block_t closeAudioFiles = ^{
        if (inAudioFile) {
            AudioFileClose(inAudioFile);
        }
        if (downFile) {
            AudioFileClose(downFile);
        }
        if (upFile) {
            AudioFileClose(upFile);
        }
    };
    
    OSStatus result = AudioFileOpenURL((__bridge CFURLRef)originalFile, kAudioFileReadPermission, 0, &inAudioFile);
    if (result != noErr) {
        os_log_error(OS_LOG_DEFAULT, "Error opening system audio file at path %{public}@ %d %@", originalFile.path, result, UTCreateStringForOSType(result));
        closeAudioFiles();
        return NO;
    } else {
        os_log_info(OS_LOG_DEFAULT, "Opened system audio file at path %{public}@", originalFile.path);
    }
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 specifierSize    = sizeof(asbd);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyDataFormat, &specifierSize, &asbd);
    NSAssert2(noErr == result, @"Error getting absd for system audio file %d %@", result, UTCreateStringForOSType(result));
    if (result != noErr) {
        os_log_error(OS_LOG_DEFAULT, "Error getting absd for system audio file %d %@", result, UTCreateStringForOSType(result));
        closeAudioFiles();
        return NO;
    }
    
    UInt64 totalBytes = 0;
    specifierSize = sizeof(totalBytes);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyAudioDataByteCount, &specifierSize, &totalBytes);
    NSAssert1(noErr == result, @"Error getting audio byte count %d", result);
    
    // Check validity of source file by expected number of audio bytes
    NSAssert2(kDefaultSystemSoundExpectedAudioBytes == totalBytes, @"Unexpected default system sound audio byte count! %llu vs %llu", totalBytes, kDefaultSystemSoundExpectedAudioBytes);
    if (kDefaultSystemSoundExpectedAudioBytes != totalBytes) {
        os_log_error(OS_LOG_DEFAULT, "Unexpected default system sound audio byte count! %llu vs %llu", totalBytes, kDefaultSystemSoundExpectedAudioBytes);
        closeAudioFiles();
        return NO;
    }
    
    UInt64 packetCount = 0;
    specifierSize = sizeof(packetCount);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyAudioDataPacketCount, &specifierSize, &packetCount);
    NSAssert1(noErr == result, @"Error getting audio packet count %d", result);
    UInt32 packetSize = 0;
    specifierSize = sizeof(packetSize);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyMaximumPacketSize, &specifierSize, &packetSize);
    NSAssert1(noErr == result, @"Error getting audio packet size %d", result);

    NSURL *downFileURL = [NSURL fileURLWithPath:self.class.defaultDownFilePath];
    NSURL *upFileURL = [NSURL fileURLWithPath:self.class.defaultUpFilePath];
    
    OSStatus (^createOutFile)(NSURL*,AudioFileID*) = ^OSStatus(NSURL *fileURL, AudioFileID *audioFile) {
        OSStatus result = AudioFileCreateWithURL((__bridge CFURLRef)fileURL, kAudioFileAIFFType, &asbd, kAudioFileFlags_EraseFile, audioFile);

        NSAssert1(noErr == result, @"Error setting absd for audio file %d", result);
        if (result != noErr) {
            os_log_error(OS_LOG_DEFAULT, "Error creating audio file at path %{public}@ %d", downFileURL.path, result);

        } else {
            os_log_info(OS_LOG_DEFAULT, "Opened output audio file at path %{public}@", downFileURL.path);
        }
        return result;
    };

    OSStatus upResult = createOutFile(upFileURL, &upFile);
    OSStatus downResult = createOutFile(downFileURL, &downFile);
    
    if (upResult != noErr || downResult != noErr) {
        closeAudioFiles();
        return NO;
    }
    
    NSMutableData *audioDataBuffer = [NSMutableData dataWithLength:totalBytes];
    UInt32 bytesToRead = (UInt32)totalBytes;
    UInt32 packetsToRead = (UInt32)packetCount;
    result = AudioFileReadPacketData(inAudioFile, false, &bytesToRead, NULL, 0, &packetsToRead, audioDataBuffer.mutableBytes);
    NSAssert1(noErr == result, @"Error reading system audio file data %d", result);
    audioDataBuffer.length = bytesToRead;
    
    UInt32 halfPackets = packetsToRead / 2;
    UInt32 halfBytes = halfPackets * packetSize;
    NSData *downData = [[audioDataBuffer subdataWithRange:NSMakeRange(0, halfBytes)] copy];
    NSData *upData = [[audioDataBuffer subdataWithRange:NSMakeRange(halfBytes, halfBytes)] copy];
    
    
    OSStatus (^writeOutFile)(NSData*,AudioFileID) = ^OSStatus(NSData *audioData, AudioFileID audioFile) {
        UInt32 bytesToWrite = (UInt32)audioData.length;
        UInt32 packetsToWrite = halfPackets;
        OSStatus result = AudioFileWritePackets(audioFile, false, bytesToWrite, NULL, 0, &packetsToWrite, audioData.bytes);
        NSAssert1(noErr == result, @"Error writing audio data %d", result);
        result = AudioFileOptimize(audioFile);
        return result;
    };

    result = writeOutFile(downData, downFile);
    result = writeOutFile(upData, upFile);
  
    closeAudioFiles();
    
    return YES;
}

@end

// MARK: - File Paths

@implementation HTKSounds (FilePaths)

+ (NSString*) defaultUpFilePath {
    NSString *filePath = [self.defaultSoundsDirectory stringByAppendingPathComponent:kDefaultUpSoundFileName];
    return filePath;
}

+ (NSString*) defaultDownFilePath {
    NSString *filePath = [self.defaultSoundsDirectory stringByAppendingPathComponent:kDefaultDownSoundFileName];
    return filePath;
}

+ (NSString*) defaultSoundsDirectory {
    NSString *applicationSupportDirectory = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).lastObject;
    NSString *applicationName = NSBundle.mainBundle.infoDictionary[(NSString*)kCFBundleNameKey];
    NSString *appDirectory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    NSString *soundsDirectory = [appDirectory stringByAppendingPathComponent:@"Sounds"];
    NSParameterAssert(soundsDirectory);
    return soundsDirectory;
}

@end


// MARK: - User Defaults

@implementation HTKSounds (UserDefaults)

+ (void) setFingerUpFilePath:(nullable NSString *)fingerUpFilePath {
    if (fingerUpFilePath) {
        [NSUserDefaults.standardUserDefaults setObject:fingerUpFilePath forKey:kFingerUpFilePathKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:kFingerUpFilePathKey];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
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
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (nullable NSString*) fingerDownFilePath {
    return [NSUserDefaults.standardUserDefaults stringForKey:kFingerDownFilePathKey];
}

/// returns valid volume range within 0.0->1.0
+ (float) validVolume:(float)value {
    if (value > 1.0) {
        return 1.0;
    } else if (value < 0.0) {
        return 0.0;
    } else {
        return value;
    }
}

+ (float) desiredVolume {
    // default to 1.0 if unset
    if(![NSUserDefaults.standardUserDefaults objectForKey:kDesiredVolumeKey]){
        return 1.0;
    }
    float value = [NSUserDefaults.standardUserDefaults floatForKey:kDesiredVolumeKey];
    return [self validVolume:value];
}

+ (void) setDesiredVolume:(float)desiredVolume {
    float value = [self validVolume:desiredVolume];
    [NSUserDefaults.standardUserDefaults setFloat:value forKey:kDesiredVolumeKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void) resetDefaultSounds {
    [self createDefaultSoundFiles];
    self.class.fingerUpFilePath = self.class.defaultUpFilePath;
    self.class.fingerDownFilePath = self.class.defaultDownFilePath;
    [self checkValidityOfUserSoundPreferences];
    [self reloadPlayers];
}

@end

NS_ASSUME_NONNULL_END
