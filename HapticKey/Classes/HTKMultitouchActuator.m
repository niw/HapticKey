//
//  HTKMultitouchActuator.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/3/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKMultitouchActuator.h"

@import IOKit;
@import os.log;

NS_ASSUME_NONNULL_BEGIN

CF_EXPORT CFTypeRef MTActuatorCreateFromDeviceID(UInt64 deviceID);
CF_EXPORT IOReturn MTActuatorOpen(CFTypeRef actuatorRef);
CF_EXPORT IOReturn MTActuatorClose(CFTypeRef actuatorRef);
// NOTE: There are unknown arguments.
// unknown1, unknown2, and unknown 3 are used to calcutate waveform.
// unknown1 looks like a 32bit bit fields and passed to 4th arguments of MTActuationCalculateWaveform().
// Give 0 or 0.0 for these arguments should be okay.
CF_EXPORT IOReturn MTActuatorActuate(CFTypeRef actuatorRef, SInt32 actuationID, UInt32 unknown1, Float32 unknown2, Float32 unknown3);
CF_EXPORT bool MTActuatorIsOpen(CFTypeRef actuatorRef);

@interface HTKMultitouchActuator ()

@end

@implementation HTKMultitouchActuator {
    CFTypeRef _actuatorRef;
}

+ (instancetype)sharedActuator
{
    static dispatch_once_t onceToken;
    static HTKMultitouchActuator *sharedActuator;
    dispatch_once(&onceToken, ^{
        sharedActuator = [[HTKMultitouchActuator alloc] init];
    });
    return sharedActuator;
}

- (void)dealloc
{
    [self _htk_main_closeActuator];
}

- (BOOL)actuateActuationID:(SInt32)actuationID unknown1:(UInt32)unknown1 unknown2:(Float32)unknown2 unknown3:(Float32)unknown3
{
    [self _htk_main_openActuator];
    BOOL result = [self _htk_main_actuateActuationID:actuationID unknown1:unknown1 unknown2:unknown2 unknown3:unknown3];

    // In case we failed to actuate with existing actuator, reopen it and try again.
    if (!result) {
        [self _htk_main_closeActuator];
        [self _htk_main_openActuator];
        result = [self _htk_main_actuateActuationID:actuationID unknown1:unknown1 unknown2:unknown2 unknown3:unknown3];
    }

    return result;
}

- (void)_htk_main_openActuator
{
    if (_actuatorRef) {
        return;
    }

    // By using IORegistoryExploere, which is in Additional Tools for Xcode,
    // Find `AppleMultitouchDevice` which has `Multitouch ID`.
    // Probably this is a fixed value.
    const CFTypeRef actuatorRef = MTActuatorCreateFromDeviceID(0x200000001000000);
    if (!actuatorRef) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorCreateFromDeviceID");
        return;
    }
    _actuatorRef = actuatorRef;

    const IOReturn error = MTActuatorOpen(actuatorRef);
    if (error != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorOpen: %p error: %d", _actuatorRef, error);
        CFRelease(_actuatorRef);
        _actuatorRef = nil;
        return;
    }
}

- (void)_htk_main_closeActuator
{
    if (!_actuatorRef) {
        return;
    }

    const IOReturn error = MTActuatorClose(_actuatorRef);
    if (error != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorClose: %p error: %d", _actuatorRef, error);
    }
    CFRelease(_actuatorRef);
    _actuatorRef = nil;
}

- (BOOL)_htk_main_actuateActuationID:(SInt32)actuationID unknown1:(UInt32)unknown1 unknown2:(Float32)unknown2 unknown3:(Float32)unknown3
{
    const IOReturn error = MTActuatorActuate(_actuatorRef, actuationID, unknown1, unknown2, unknown3);
    if (error != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorActuate: %p, %d, %d, %f, %f error: %d", _actuatorRef, actuationID, unknown1, unknown2, unknown3, error);
        return NO;
    } else {
        return YES;
    }
}

@end

NS_ASSUME_NONNULL_END
