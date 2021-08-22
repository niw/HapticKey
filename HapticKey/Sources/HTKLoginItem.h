//
//  HTKLoginItem.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/23/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class HTKLoginItem;

@protocol HTKLoginItemDelegate <NSObject>

@optional
- (void)loginItemDidChange:(HTKLoginItem *)loginItem;

@end

@interface HTKLoginItem : NSObject

@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, weak, nullable) id<HTKLoginItemDelegate> delegate;
@property (nonatomic, getter=isEnabled) BOOL enabled;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
