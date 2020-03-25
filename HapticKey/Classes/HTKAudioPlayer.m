//
//  HTKAudioPlayer.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 3/24/20.
//  Copyright © 2020 Yoshimasa Niwa. All rights reserved.
//

#import "HTKAudioPlayer.h"

@import AVFoundation;
@import os.log;

NS_ASSUME_NONNULL_BEGIN

static NSString * const kSystemSoundsPath = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds";

@interface HTKAudioPlayer ()

@property (nonatomic, readonly) AVPlayer *player;

@end

@implementation HTKAudioPlayer

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

static const char kAVPlayerStatusObservingTag;
static NSString * const kAVPlayerStatusKeyPath = @"status";

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        _path = [path copy];

        NSURL * const url = [[NSURL alloc] initFileURLWithPath:path];
        _player = [[AVPlayer alloc] initWithURL:url];

        // Neither key-value observer nor observable are retained. Should remove the observer on its `dealloc`.
        [_player addObserver:self forKeyPath:kAVPlayerStatusKeyPath options:0 context:(void *)&kAVPlayerStatusObservingTag];
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
    [self.player removeObserver:self forKeyPath:kAVPlayerStatusKeyPath context:(void *)&kAVPlayerStatusObservingTag];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey,id> *)change context:(nullable void *)context
{
    if ([keyPath isEqualToString:kAVPlayerStatusKeyPath] && object == self.player) {
        switch (self.player.status) {
            case AVPlayerStatusFailed:
                os_log_error(OS_LOG_DEFAULT, "Player is not ready to play sound at path: %{public}@ error: %{public}@", self.path, self.player.error);
                return;
            case AVPlayerStatusReadyToPlay:
                os_log_info(OS_LOG_DEFAULT, "Player is ready to play sound at path: %{public}@", self.path);
                break;
            default:
                break;
        }
    }
}

- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

- (float)volume
{
    return self.player.volume;
}

- (void)play
{
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    [self.player playImmediatelyAtRate:1.0];
}

@end

NS_ASSUME_NONNULL_END
