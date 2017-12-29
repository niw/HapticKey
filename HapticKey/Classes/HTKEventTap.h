//
//  HTKEventTap.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/13/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

@import AppKit;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class HTKEventTap;

@protocol HTKEventTapDelegate <NSObject>

@optional
- (void)eventTap:(HTKEventTap *)eventTap didTapEvent:(NSEvent *)event;
- (void)eventTapDisabled:(HTKEventTap *)eventTap;

@end

@interface HTKEventTap : NSObject

@property (nonatomic, weak, nullable) id<HTKEventTapDelegate> delegate;
@property (nonatomic, readonly) CGEventMask eventMask;
@property (nonatomic, getter=isEnabled) BOOL enabled;

- (instancetype)initWithEventMask:(CGEventMask)eventMask NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
