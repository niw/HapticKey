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
@class HTKSounds;

typedef NS_ENUM(NSUInteger, HTKHapticFeedbackType) {
    HTKHapticFeedbackTypeNone,
    HTKHapticFeedbackTypeWeak,
    HTKHapticFeedbackTypeMedium,
    HTKHapticFeedbackTypeStrong
};

typedef NS_ENUM(NSUInteger, HTKSoundFeedbackType) {
    HTKSoundFeedbackTypeNone,
    HTKSoundFeedbackTypeDefault
};

@interface HTKHapticFeedback : NSObject

@property (nonatomic, readonly) HTKEventListener *eventListener;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic) HTKHapticFeedbackType type;
@property (nonatomic) HTKSoundFeedbackType soundType;
@property (nonatomic, readonly, nullable) HTKSounds *sounds;
@property (nonatomic, getter=isScreenFlashEnabled) BOOL screenFlashEnabled;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithEventListener:(HTKEventListener *)eventListener
                               sounds:(nullable HTKSounds*)sounds NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
