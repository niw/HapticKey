//
//  HTKHapticFeedback.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEvent.h"
#import "HTKEventListener.h"
#import "HTKHapticFeedback.h"
#import "HTKMultitouchActuator.h"
#import "HTKSystemSound.h"
#import "HTKTimer.h"

@import AudioToolbox;

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval kMinimumActuationInterval = 0.05;

static NSString * const kDefaultSystemSoundsGroup = @"ink";
static NSString * const kDefaultSystemSoundsName = @"InkSoundBecomeMouse.aif";

@interface HTKHapticFeedback () <HTKEventListenerDelegate>

@property (nonatomic, nullable) HTKTimer *timer;
@property (nonatomic, readonly) HTKSystemSound *defaultSystemSound;

@end

@implementation HTKHapticFeedback

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)initWithEventListener:(HTKEventListener *)eventListener
{
    if (self = [super init]) {
        _eventListener = eventListener;
        _eventListener.delegate = self;
        _type = HTKHapticFeedbackTypeMedium;

        _defaultSystemSound = [[HTKSystemSound alloc] initWithSystemSoundsGroup:kDefaultSystemSoundsGroup name:kDefaultSystemSoundsName];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled
{
    self.eventListener.enabled = enabled;
}

- (BOOL)isEnabled
{
    return self.eventListener.enabled;
}

// MARK: - HTKEventListenerDelegate

- (void)eventListener:(HTKEventListener *)eventListener didListenEvent:(HTKEvent *)event
{
    // Start a timer to prevent frequent actuations.
    if (self.timer) {
        return;
    }
    self.timer = [[HTKTimer alloc] initWithInterval:kMinimumActuationInterval target:self selector:@selector(_htk_timer_didFire:)];

    const SInt32 actuationID = [self _htk_main_actuationID];
    HTKSystemSound * const systemSound = [self _htk_main_systemSound];
    switch (event.phase) {
        case HTKEventPhaseBegin:
            if (actuationID != 0) {
                [[HTKMultitouchActuator sharedActuator] actuateActuationID:actuationID unknown1:0 unknown2:0.0 unknown3:2.0];
            }
            if (systemSound) {
                [systemSound play];
            }
            if (self.screenFlashEnabled) {
                AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_FlashScreen, NULL);
            }
            break;
        case HTKEventPhaseEnd:
            if (actuationID != 0) {
                [[HTKMultitouchActuator sharedActuator] actuateActuationID:actuationID unknown1:0 unknown2:0.0 unknown3:0.0];
            }
            break;
    }
}

- (void)_htk_timer_didFire:(HTKTimer *)timer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (SInt32)_htk_main_actuationID
{
    // To find predefiend actuation ID, run next command.
    // $ otool -s __TEXT __tpad_act_plist /System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/Current/MultitouchSupport|tail -n +3|awk -F'\t' '{print $2}'|xxd -r -p
    // This show a embeded property list file in `MultitouchSupport.framework`.
    // There are default 1, 2, 3, 4, 5, 6, 15, and 16 actuation IDs now.

    switch (self.type) {
        case HTKHapticFeedbackTypeNone:
            return 0;
        case HTKHapticFeedbackTypeWeak:
            return 3;
        case HTKHapticFeedbackTypeMedium:
            return 4;
        case HTKHapticFeedbackTypeStrong:
            return 6;
    }
    return 0;
}

- (nullable HTKSystemSound *)_htk_main_systemSound
{
    switch (self.soundType) {
        case HTKSoundFeedbackTypeNone:
            return nil;
        case HTKSoundFeedbackTypeDefault:
            return self.defaultSystemSound;
    }
}

@end

NS_ASSUME_NONNULL_END
