//
//  HTKEvent.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEvent.h"

@implementation HTKEvent

- (instancetype)initWithPhase:(HTKEventPhase)phase
{
    if (self = [super init]) {
        _phase = phase;
    }
    return self;
}

@end
