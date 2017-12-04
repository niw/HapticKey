//
//  HTKMultiTouchActuator.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/3/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface HTKMultiTouchActuator : NSObject

+ (instancetype)sharedActuator;

- (BOOL)actuateActuationID:(SInt32)actuationID unknown1:(UInt32)unknown1 unknown2:(Float32)unknown2 unknown3:(Float32)unknown3;

@end

NS_ASSUME_NONNULL_END
