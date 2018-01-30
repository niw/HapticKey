//
//  HTKSystemSound.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/29/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface HTKSystemSound : NSObject

@property (nonatomic, readonly) NSString *path;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithSystemSoundsGroup:(NSString *)group name:(NSString *)name;

- (void)play;

@end

NS_ASSUME_NONNULL_END
