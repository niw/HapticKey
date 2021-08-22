//
//  NSTouchDevice.h
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/13/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

// This file is created from `AppKit.framework`.

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NSTouchDeviceType) {
    NSTouchDeviceTypeUnknown1 = 0,
    NSTouchDeviceTypeTrackpad = 1,
    NSTouchDeviceTypeUnknown2 = 2,
    NSTouchDeviceTypeTouchBar = 3
};

@interface NSTouchDevice : NSObject

@property (class, nonatomic, readonly) NSArray<NSTouchDevice *> *touchDevices;
@property (nonatomic, readonly) NSTouchDeviceType deviceType;

@property (nonatomic, readonly) BOOL hasActuation;

@end

@interface NSTouch (NSTouchDevice)

@property (readonly) NSTouchDevice *device;

@end

NS_ASSUME_NONNULL_END
