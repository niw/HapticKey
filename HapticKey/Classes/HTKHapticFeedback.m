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

NS_ASSUME_NONNULL_BEGIN

@interface HTKHapticFeedback () <HTKEventListenerDelegate>

@end

@implementation HTKHapticFeedback

- (instancetype)initWithEventListener:(HTKEventListener *)eventListener
{
    if (self = [super init]) {
        _eventListener = eventListener;
        _eventListener.delegate = self;
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
    switch (event.phase) {
        case HTKEventPhaseBegin:
            [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:2.0];
            break;
        case HTKEventPhaseEnd:
            [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:0.0];
            break;
    }
}

@end

NS_ASSUME_NONNULL_END
