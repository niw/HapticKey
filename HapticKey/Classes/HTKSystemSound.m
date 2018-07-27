//
//  HTKSystemSound.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/29/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKSystemSound.h"

@import AudioToolbox;
@import os.log;

NS_ASSUME_NONNULL_BEGIN

static NSString * const kSystemSoundsPath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds";

@interface HTKSystemSound ()

@property (nonatomic, readonly) SystemSoundID systemSoundID;

@end

@implementation HTKSystemSound

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        _path = [path copy];

        SystemSoundID systemSoundID;
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &systemSoundID);
        if (error != noErr) {
            os_log_error(OS_LOG_DEFAULT, "Fail to create system sound at path: %{public}@ code: 0x%lx", path, (long)error);
            return nil;
        } else {
            os_log_info(OS_LOG_DEFAULT, "Create system sound at path: %{public}@ id: 0x%lx", path, (long)systemSoundID);
        }
        _systemSoundID = systemSoundID;
    }
    return self;
}

- (instancetype)initWithSystemSoundsGroup:(NSString *)group name:(NSString *)name
{
    NSString * const path = [[kSystemSoundsPath stringByAppendingPathComponent:group] stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

- (void)dealloc
{
    OSStatus error = AudioServicesDisposeSystemSoundID(self.systemSoundID);
    if (error != noErr) {
        os_log_error(OS_LOG_DEFAULT, "Fail to dispose system sound id: %lu code: 0x%lx", (long)self.systemSoundID, (long)error);
    }
}

- (void)play
{
    AudioServicesPlaySystemSoundWithCompletion(self.systemSoundID, NULL);
}

@end

NS_ASSUME_NONNULL_END
