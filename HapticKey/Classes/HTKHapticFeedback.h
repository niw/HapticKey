//
//  HTKHapticFeedback.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class HTKEventListener;

typedef NS_ENUM(NSUInteger, HTKHapticFeedbackType) {
    HTKHapticFeedbackTypeWeak,
    HTKHapticFeedbackTypeMedium,
    HTKHapticFeedbackTypeStrong
};

@interface HTKHapticFeedback : NSObject

@property (nonatomic, readonly) HTKEventListener *eventListener;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic) HTKHapticFeedbackType type;

- (instancetype)initWithEventListener:(HTKEventListener *)eventListener;

@end

NS_ASSUME_NONNULL_END
