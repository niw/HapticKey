//
//  HTKEvent.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HTKEvent

- (instancetype)init
{
    return [self initWithPhase:HTKEventPhaseBegin];
}

- (instancetype)initWithPhase:(HTKEventPhase)phase
{
    if (self = [super init]) {
        _phase = phase;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
