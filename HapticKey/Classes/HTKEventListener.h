//
//  HTKEventListener.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class HTKEventListener;
@class HTKEvent;

@protocol HTKEventListenerDelegate <NSObject>

@optional
- (void)eventListener:(HTKEventListener *)eventListener didListenEvent:(HTKEvent *)event;

@end

@interface HTKEventListener : NSObject

@property (nonatomic, weak) id<HTKEventListenerDelegate> delegate;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
