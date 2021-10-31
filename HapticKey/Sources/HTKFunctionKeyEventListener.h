//
//  HTKFunctionKeyEventListener.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/14/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKEventListener.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HTKFunctionKeyEventListenerKeyboardType) {
    HTKFunctionKeyEventListenerKeyboardTypeAny = 0,
    HTKFunctionKeyEventListenerKeyboardTypeTouchBar
};

@interface HTKFunctionKeyEventListener : HTKEventListener

- (instancetype)initWithKeyboardType:(HTKFunctionKeyEventListenerKeyboardType)keyboardType NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
