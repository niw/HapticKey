//
//  HTKMultitouchActuator.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 12/3/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "HTKMultitouchActuator.h"

@import IOKit;

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
    if (_actuatorRef) {
        const IOReturn error = MTActuatorClose(_actuatorRef);
        if (error != kIOReturnSuccess) {
            // TODO: Logging.
        }
        CFRelease(_actuatorRef);
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        // By using IORegistoryExploere, which is in Additional Tools for Xcode,
        // Find `AppleMultitouchDevice` which has `Multitouch ID`.
        // Probably this is a fixed value.
        const CFTypeRef actuatorRef = MTActuatorCreateFromDeviceID(0x200000001000000);
        if (!actuatorRef) {
            // TODO: Logging.
            return nil;
        }
        _actuatorRef = actuatorRef;

        const IOReturn error = MTActuatorOpen(actuatorRef);
        if (error != kIOReturnSuccess) {
            // TODO: Logging.
            CFRelease(_actuatorRef);
            return nil;
        }
    }
    return self;
}

- (BOOL)actuateActuationID:(SInt32)actuationID unknown1:(UInt32)unknown1 unknown2:(Float32)unknown2 unknown3:(Float32)unknown3
{
    const IOReturn error = MTActuatorActuate(_actuatorRef, actuationID, unknown1, unknown2, unknown3);
    if (error != kIOReturnSuccess) {
        // TODO: Logging.
        return NO;
    } else {
        return YES;
    }
}

@end

NS_ASSUME_NONNULL_END
