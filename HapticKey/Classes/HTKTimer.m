//
//  HTKTimer.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/13/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKTimer.h"

@import ObjectiveC;

NS_ASSUME_NONNULL_BEGIN

@interface HTKTimer ()

@property (nonatomic, readonly, nullable) NSTimer *timer;

@end

@implementation HTKTimer

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)initWithInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector
{
    if (self = [super init]) {
        _target = target;
        _selector = selector;

        // NOTE: `NSTimer` retains `target` and we really need to release `_timer` when we invalidate it.
        _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(_htk_timer_didFire:) userInfo:nil repeats:NO];
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)invalidate
{
    [_timer invalidate];
    _timer = nil;
}

// MARK: - Timer

- (void)_htk_timer_didFire:(NSTimer *)timer
{
    typeof (_target) target = self.target;
    SEL selector = self.selector;

    if (target && selector) {
        void (*msgSend)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
        msgSend(target, selector, self);
    }

    [self invalidate];
}

@end

NS_ASSUME_NONNULL_END
