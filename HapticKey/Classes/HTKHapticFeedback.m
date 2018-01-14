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
#import "HTKTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTKHapticFeedback () <HTKEventListenerDelegate>

@property (nonatomic, nullable) HTKTimer *timer;

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

static const NSTimeInterval kMinimumActuationInterval = 0.05;

- (void)eventListener:(HTKEventListener *)eventListener didListenEvent:(HTKEvent *)event
{
    // Start a timer to prevent frequent actuations.
    if (self.timer) {
        return;
    }
    self.timer = [[HTKTimer alloc] initWithInterval:kMinimumActuationInterval target:self selector:@selector(_htk_timer_didFire:)];

    const SInt32 actuationID = [self _htk_main_actuationID];
    switch (event.phase) {
        case HTKEventPhaseBegin:
            [[HTKMultitouchActuator sharedActuator] actuateActuationID:actuationID unknown1:0 unknown2:0.0 unknown3:2.0];
            break;
        case HTKEventPhaseEnd:
            [[HTKMultitouchActuator sharedActuator] actuateActuationID:actuationID unknown1:0 unknown2:0.0 unknown3:0.0];
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
        case HTKHapticFeedbackTypeWeak:
            return 3;
        case HTKHapticFeedbackTypeMedium:
            return 4;
        case HTKHapticFeedbackTypeStrong:
            return 6;
    }
    return 0;
}

@end

NS_ASSUME_NONNULL_END
