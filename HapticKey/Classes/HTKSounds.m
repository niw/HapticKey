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

static NSString * const kDefaultSystemSoundFilePath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/ink/InkSoundBecomeMouse.aif";

//static NSString * const kDefaultSystemSoundFilePath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Media Keys.aif";

static NSString * const kFingerUpFilePathKey = @"FingerUpFilePath";
static NSString * const kFingerDownFilePathKey = @"FingerDownFilePath";

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

// MARK: - Public

- (void) playFingerUp {
    [self.fingerUp play];
}

- (void) playFingerDown {
    [self.fingerDown play];
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
        NSURL *fileURL = [NSURL fileURLWithPath:fingerDownFilePath];
        _fingerDown = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    }
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

- (BOOL) resetDefaultSounds {
    
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
    UInt64 packetCount = 0;
    specifierSize = sizeof(packetCount);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyAudioDataPacketCount, &specifierSize, &packetCount);
    NSAssert1(noErr == result, @"Error getting audio packet count %d", result);
    UInt32 packetSize = 0;
    specifierSize = sizeof(packetSize);
    result = AudioFileGetProperty(inAudioFile, kAudioFilePropertyMaximumPacketSize, &specifierSize, &packetSize);
    NSAssert1(noErr == result, @"Error getting audio packet size %d", result);

    
    NSURL* (^createOutURL)(NSString*) = ^NSURL*(NSString *suffix) {
        // TODO: use proper localized string
        NSString *fileName = [[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Default", @"default audio file name"), suffix] stringByAppendingPathExtension:@"aif"];
        if (!fileName) {
            return nil;
        }
        NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        return fileURL;
    };

    NSURL *downFileURL = createOutURL(@"↓");
    NSURL *upFileURL = createOutURL(@"↑");
    NSAssert(downFileURL && upFileURL, @"Could not create out file URLs");
    if (!downFileURL || !upFileURL) {
        os_log_error(OS_LOG_DEFAULT, "Could not create out file URLs");
        closeAudioFiles();
        return NO;
    }
    
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
    
    self.class.fingerUpFilePath = upFileURL.path;
    self.class.fingerDownFilePath = downFileURL.path;
    [self reloadPlayers];
    
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



@end

// MARK: - User Defaults

@implementation HTKSounds (UserDefaults)

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
