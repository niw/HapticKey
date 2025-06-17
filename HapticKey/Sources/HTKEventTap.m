//
//  HTKEventTap.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/13/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEventTap.h"

@import os.log;

NS_ASSUME_NONNULL_BEGIN

@class HTKEventTapLoop;

@protocol HTKEventTapLoopDelegate <NSObject>

@optional
- (void)eventTapLoopDidDisableEventTap:(HTKEventTapLoop *)eventTapLoop;
- (void)eventTapLoop:(HTKEventTapLoop *)eventTapLoop didTapCGEvent:(CGEventRef)eventRef;

@end

@interface HTKEventTapLoop : NSObject

@property (nonatomic, weak, nullable) id<HTKEventTapLoopDelegate> delegate;
@property (nonatomic, nullable) NSThread *thread;

@end

@implementation HTKEventTapLoop

static CGEventRef EventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void * _Nullable userInfo)
{
    // Called on the background thread.

    HTKEventTapLoop * const eventTapLoop = (__bridge HTKEventTapLoop *)userInfo;

    switch (type) {
        case kCGEventTapDisabledByTimeout:
        case kCGEventTapDisabledByUserInput: {
            os_log_error(OS_LOG_DEFAULT, "Event tap disabled by type: %d", type);

            id<HTKEventTapLoopDelegate> const delegate = eventTapLoop.delegate;
            if ([delegate respondsToSelector:@selector(eventTapLoopDidDisableEventTap:)]) {
                [delegate eventTapLoopDidDisableEventTap:eventTapLoop];
            }
            break;
        }
        default: {
            id<HTKEventTapLoopDelegate> const delegate = eventTapLoop.delegate;
            if ([delegate respondsToSelector:@selector(eventTapLoop:didTapCGEvent:)]) {
                [delegate eventTapLoop:eventTapLoop didTapCGEvent:eventRef];
            }
            break;
        }
    }

    return eventRef;
}

- (void)startWithEventMask:(CGEventMask)eventMask
{
    if (self.thread) {
        return;
    }

    __weak typeof (self) weakSelf = self;
    NSThread * const thread = [[NSThread alloc] initWithBlock:^{
        // Called on the background thread.

        typeof (self) const strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        CFMachPortRef const eventTap = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly, eventMask, EventTapCallback, (__bridge void *)strongSelf);
        if (!eventTap) {
            return;
        }

        CFRunLoopSourceRef const runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
        if (!runLoopSource) {
            CFRelease(eventTap);
            return;
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

        CGEventTapEnable(eventTap, true);
        os_log_info(OS_LOG_DEFAULT, "Event tap enabled: %p", eventTap);

        // This run loop is ended by `_htk_thread_stop` call.
        CFRunLoopRun();

        CGEventTapEnable(eventTap, false);
        os_log_info(OS_LOG_DEFAULT, "Event tap disabled: %p", eventTap);

        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);

        CFMachPortInvalidate(eventTap);
        CFRelease(eventTap);
    }];
    thread.name = @"at.niw.HapticKey.HTKEventTapLoop.thread";
    [thread start];

    self.thread = thread;
}

- (void)stop
{
    if (!self.thread) {
        return;
    }

    // `_htk_thread_stop` is called on the background thread while its run loop runs.
    [self performSelector:@selector(_htk_thread_stop) onThread:self.thread withObject:nil waitUntilDone:NO];

    self.thread = nil;
}

- (void)_htk_thread_stop
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end

// MARK: -

@interface HTKEventTap () <HTKEventTapLoopDelegate>

@property (nonatomic, nullable) HTKEventTapLoop *loop;

@end

@implementation HTKEventTap

- (instancetype)init
{
    return [self initWithEventMask:kCGEventMaskForAllEvents];
}

- (instancetype)initWithEventMask:(CGEventMask)eventMask
{
    if (self = [super init]) {
        _eventMask = eventMask;
    }
    return self;
}

- (void)dealloc
{
    [self _htk_main_disable];
}

- (BOOL)isEnabled
{
    return self.loop != nil;
}

- (void)setEnabled:(BOOL)enabled
{
    if (self.enabled != enabled) {
        if (enabled) {
            [self _htk_main_enable];
        } else {
            [self _htk_main_disable];
        }
    }
}

- (void)_htk_main_enable
{
    if (self.loop) {
        return;
    }

    HTKEventTapLoop * const loop = [[HTKEventTapLoop alloc] init];
    loop.delegate = self;
    [loop startWithEventMask:self.eventMask];

    self.loop = loop;
}

- (void)_htk_main_disable
{
    if (!self.loop) {
        return;
    }

    [self.loop stop];

    self.loop = nil;
}

// MARK: - HTKEventTapLoopDelegate

- (void)eventTapLoopDidDisableEventTap:(HTKEventTapLoop *)eventTapLoop
{
    // Called on the background thread.

    __weak typeof (self) const weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof (self) const strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        strongSelf.enabled = NO;

        id<HTKEventTapDelegate> delegate = strongSelf.delegate;
        if ([delegate respondsToSelector:@selector(eventTapDidDisable:)]) {
            [delegate eventTapDidDisable:strongSelf];
        }
    });
}

- (void)eventTapLoop:(HTKEventTapLoop *)eventTapLoop didTapCGEvent:(CGEventRef)eventRef
{
    // Called on the background thread.

    CFRetain(eventRef);

    __weak typeof (self) const weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof (self) const strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        id<HTKEventTapDelegate> delegate = strongSelf.delegate;
        if ([delegate respondsToSelector:@selector(eventTap:didTapEvent:)]) {
            // `eventWithCGEvent:` returns an autoreleased `NSEvent` that retains given `CGEvent`.
            // without `@autoreleasepool`, this will may leak and also `CGEvent` as well.
            @autoreleasepool {
                // `NSEvent` must be instantiate on main thread, or some properties may not be prepared such as `allTouches`.
                NSEvent * const event = [NSEvent eventWithCGEvent:eventRef];
                [delegate eventTap:strongSelf didTapEvent:event];
            }
        }

        CFRelease(eventRef);
    });
}

@end

NS_ASSUME_NONNULL_END
