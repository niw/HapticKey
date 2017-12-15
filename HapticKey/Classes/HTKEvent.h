//
//  HTKEvent.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HTKEventPhase) {
    HTKEventPhaseBegin,
    HTKEventPhaseEnd
};

@interface HTKEvent : NSObject

@property (nonatomic, readonly) HTKEventPhase phase;

- (instancetype)initWithPhase:(HTKEventPhase)phase;

@end

NS_ASSUME_NONNULL_END
