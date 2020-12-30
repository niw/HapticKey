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
// unknown1, unknown2, and unknown 3 are used to calculate waveform.
// unknown1 looks like a 32bit bit fields and passed to 4th arguments of MTActuationCalculateWaveform().
// Give 0 or 0.0 for these arguments should be okay.
CF_EXPORT IOReturn MTActuatorActuate(CFTypeRef actuatorRef, SInt32 actuationID, UInt32 unknown1, Float32 unknown2, Float32 unknown3);
CF_EXPORT bool MTActuatorIsOpen(CFTypeRef actuatorRef);

@interface HTKMultitouchActuator ()

@property (nonatomic) UInt64 lastKnownMultitouchDeviceMultitouchID;

@end

@implementation HTKMultitouchActuator
{
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

// By using IORegistryExplorer, which is in Additional Tools for Xcode,
// Find `AppleMultitouchDevice` which has `Multitouch ID`.
// Probably these are fixed value.
static const UInt64 kKnownAppleMultitouchDeviceMultitouchIDs[] = {
    // For MacBook Pro 2016, 2017
    0x200000001000000,
    // For MacBook Pro 2018
    0x300000080500000,
    // For MacBook Pro (M1, 2020)
    0x200000000000024
};

- (void)_htk_main_openActuator
{
    if (_actuatorRef) {
        return;
    }

    if (self.lastKnownMultitouchDeviceMultitouchID) {
        const CFTypeRef actuatorRef = MTActuatorCreateFromDeviceID(self.lastKnownMultitouchDeviceMultitouchID);
        if (!actuatorRef) {
            os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorCreateFromDeviceID: 0x%llx", self.lastKnownMultitouchDeviceMultitouchID);
            return;
        }
        _actuatorRef = actuatorRef;
    } else {
        const size_t count = sizeof(kKnownAppleMultitouchDeviceMultitouchIDs) / sizeof(UInt64);
        for (size_t index = 0; index < count; index++) {
            const UInt64 multitouchDeviceMultitouchID = kKnownAppleMultitouchDeviceMultitouchIDs[index];
            const CFTypeRef actuatorRef = MTActuatorCreateFromDeviceID(multitouchDeviceMultitouchID);
            if (actuatorRef) {
                os_log_info(OS_LOG_DEFAULT, "Use MTActuatorCreateFromDeviceID: 0x%llx", multitouchDeviceMultitouchID);
                _actuatorRef = actuatorRef;
                self.lastKnownMultitouchDeviceMultitouchID = multitouchDeviceMultitouchID;
                break;
            }
            os_log_info(OS_LOG_DEFAULT, "Fail to test MTActuatorCreateFromDeviceID: 0x%llx", multitouchDeviceMultitouchID);
        }
        if (!_actuatorRef) {
            os_log_info(OS_LOG_DEFAULT, "Fail to MTActuatorCreateFromDeviceID");
            return;
        }
    }

    const IOReturn error = MTActuatorOpen(_actuatorRef);
    if (error != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorOpen: %p error: 0x%x", _actuatorRef, error);
        CFRelease(_actuatorRef);
        _actuatorRef = NULL;
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
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorClose: %p error: 0x%x", _actuatorRef, error);
    }
    CFRelease(_actuatorRef);
    _actuatorRef = NULL;
}

- (BOOL)_htk_main_actuateActuationID:(SInt32)actuationID unknown1:(UInt32)unknown1 unknown2:(Float32)unknown2 unknown3:(Float32)unknown3
{
    if (!_actuatorRef) {
        os_log_error(OS_LOG_DEFAULT, "The actuator is not opened yet.");
        return NO;
    }

    const IOReturn error = MTActuatorActuate(_actuatorRef, actuationID, unknown1, unknown2, unknown3);
    if (error != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "Fail to MTActuatorActuate: %p, %d, %d, %f, %f error: 0x%x", _actuatorRef, actuationID, unknown1, unknown2, unknown3, error);
        return NO;
    } else {
        return YES;
    }
}

@end

NS_ASSUME_NONNULL_END
