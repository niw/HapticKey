//
//  HTKAudioPlayer.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 3/24/20.
//  Copyright © 2020 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface HTKAudioPlayer : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic) float volume;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithSystemSoundsGroup:(NSString *)group name:(NSString *)name;

- (void)play;

@end

NS_ASSUME_NONNULL_END
