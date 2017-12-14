//
//  HTKEventTap.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/13/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEventTap.h"

NS_ASSUME_NONNULL_BEGIN

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type,  CGEventRef eventRef, void * _Nullable userInfo) {
    __unsafe_unretained HTKEventTap * const eventTap = (__bridge HTKEventTap *)userInfo;
    NSEvent * const event = [NSEvent eventWithCGEvent:eventRef];

    id<HTKEventTapDelegate> const delegate = eventTap.delegate;
    if ([delegate respondsToSelector:@selector(eventTap:didTapEvent:)]) {
        [delegate eventTap:eventTap didTapEvent:event];
    }

    return eventRef;
}

@implementation HTKEventTap {
    CFMachPortRef _eventTap;
    CFRunLoopSourceRef _runLoopSource;
}

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

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        if (enabled) {
            [self _htk_main_enable];
        } else {
            [self _htk_main_disable];
        }
    }
}

- (void)_htk_main_enable
{
    if (_eventTap) {
        return;
    }
    if (_runLoopSource) {
        return;
    }

    _eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, self.eventMask, eventTapCallback, (__bridge void *)self);
    if (_eventTap) {
        _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);
        if (_runLoopSource) {
            CFRunLoopAddSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);
            CGEventTapEnable(_eventTap, true);
            _enabled = YES;
        } else {
            CFRelease(_eventTap);
            _eventTap = NULL;
        }
    }
}

- (void)_htk_main_disable
{
    if (_runLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);
        CFRelease(_runLoopSource);
        _runLoopSource = NULL;
    }
    if (_eventTap) {
        CGEventTapEnable(_eventTap, false);
        CFRelease(_eventTap);
        _eventTap = NULL;
    }

    _enabled = NO;
}

@end

NS_ASSUME_NONNULL_END
