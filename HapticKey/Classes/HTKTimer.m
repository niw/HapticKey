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

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval repeats:(BOOL)repeats target:(id)target selector:(SEL)selector
{
    if (self = [super init]) {
        _repeats = repeats;
        _target = target;
        _selector = selector;

        __weak typeof (self) const weakSelf = self;
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval repeats:repeats block:^(NSTimer *timer) {
            typeof (self) const strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            [strongSelf _htk_timer_didFire:timer];
        }];
    }
    return self;
}

- (void)dealloc
{
    [self invalidate];
}

- (NSTimeInterval)timeInterval
{
    return _timer.timeInterval;
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

    if (!self.repeats) {
        [self invalidate];
    }
}

@end

NS_ASSUME_NONNULL_END
