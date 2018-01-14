//
//  HTKTimer.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/13/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface HTKTimer : NSObject

@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly) SEL selector;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector NS_DESIGNATED_INITIALIZER;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
