//
//  HTKFunctionKeyEventListener.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEvent.h"
#import "HTKEventTap.h"
#import "HTKFunctionKeyEventListener.h"

@import AppKit;

NS_ASSUME_NONNULL_BEGIN

// A list of key code of ESC and F1 to F12.
static int64_t const kEscAndFunctionKeycodes[] = {
    53, // ESC
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111 // F1 to F12
};
static const NSUInteger kNumberOfEscAndFunctionKeycodes = sizeof (kEscAndFunctionKeycodes) / sizeof (int64_t);
static const int64_t kTouchbarKeyboardType = 198;

@interface HTKFunctionKeyEventListener () <HTKEventTapDelegate>

@property (nonatomic, readonly) HTKEventTap *eventTap;

@end

@implementation HTKFunctionKeyEventListener

- (instancetype)init
{
    if (self = [super init]) {
        const CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
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

- (void)eventTap:(HTKEventTap *)eventTap didTapEvent:(NSEvent *)event
{
    const int64_t keyboardType = CGEventGetIntegerValueField(event.CGEvent, kCGKeyboardEventKeyboardType);
    if (keyboardType == kTouchbarKeyboardType && !event.ARepeat) {
        for (NSUInteger index = 0; index < kNumberOfEscAndFunctionKeycodes; index += 1) {
            if (kEscAndFunctionKeycodes[index] == event.keyCode) {
                switch (event.type) {
                    case NSEventTypeKeyDown:
                        [self _htk_main_didListenEvent:[[HTKEvent alloc] initWithPhase:HTKEventPhaseBegin]];
                        break;
                    case NSEventTypeKeyUp:
                        [self _htk_main_didListenEvent:[[HTKEvent alloc] initWithPhase:HTKEventPhaseEnd]];
                        break;
                    default:
                        // Should not reach here.
                        break;
                }
                break;
            }
        }
    }
}

- (void)eventTapDidDisable:(HTKEventTap *)eventTap
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
