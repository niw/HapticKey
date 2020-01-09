//
//  HTKTapGestureEventListener.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEvent.h"
#import "HTKEventTap.h"
#import "HTKTapGestureEventListener.h"
#import "NSTouchDevice.h"

@import AppKit;
@import IOKit;

NS_ASSUME_NONNULL_BEGIN

static const uint32_t kCGEventFieldTouchContextID = 0x92;

@interface HTKTapGestureEventListener () <HTKEventTapDelegate>

@property (nonatomic, readonly) HTKEventTap *eventTap;

@end

@implementation HTKTapGestureEventListener

- (instancetype)init
{
    if (self = [super init]) {
        const CGEventMask eventMask = CGEventMaskBit(NSEventTypeGesture);
        _eventTap = [[HTKEventTap alloc] initWithEventMask:eventMask];
        _eventTap.delegate = self;
    }
    return self;
}

// MARK: - HTKEventListener

- (void)setEnabled:(BOOL)enabled
{
    self.eventTap.enabled = enabled;
}

- (BOOL)isEnabled
{
    return self.eventTap.enabled;
}

// MARK: - HTKEventTapDelegate

- (void)eventTap:(HTKEventTap *)eventTap didTapCGEvent:(CGEventRef)eventRef
{
    // `eventWithCGEvent:` is relatively expensive.
    // Check touch contextID exists or not first. All touches on TouchBar has this ID.
    const int64_t contextID = CGEventGetIntegerValueField(eventRef, kCGEventFieldTouchContextID);
    if (contextID != 0) {
        NSEvent * const event = [NSEvent eventWithCGEvent:eventRef];
        for (NSTouch * const touch in [event allTouches]) {
            NSTouchDevice * const touchDevice = touch.device;
            if (!touch.resting && touchDevice.deviceType == NSTouchDeviceTypeTouchBar) {
                switch (touch.phase) {
                    case NSTouchPhaseBegan:
                        [self _htk_main_didListenEvent:[[HTKEvent alloc] initWithPhase:HTKEventPhaseBegin]];
                        return;
                    case NSTouchPhaseEnded:
                        [self _htk_main_didListenEvent:[[HTKEvent alloc] initWithPhase:HTKEventPhaseEnd]];
                        return;
                    default:
                        break;
                }
            }
        }
    }
}

- (void)eventTapDisabled:(HTKEventTap *)eventTap
{
    self.eventTap.enabled = YES;
}

- (void)_htk_main_didListenEvent:(HTKEvent *)event
{
    id<HTKEventListenerDelegate> const delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(eventListener:didListenEvent:)]) {
        [delegate eventListener:self didListenEvent:event];
    }
}

@end

NS_ASSUME_NONNULL_END
