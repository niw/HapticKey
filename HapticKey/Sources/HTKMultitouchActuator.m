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
        io_iterator_t itreator = IO_OBJECT_NULL;
        // NOTE: `IOServiceGetMatchingServices` will take ownership of `matchingRef`. Do not release it.
        const CFMutableDictionaryRef matchingRef = IOServiceMatching("AppleMultitouchDevice");
        const kern_return_t result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingRef, &itreator);
        if (result != KERN_SUCCESS) {
            os_log_info(OS_LOG_DEFAULT, "Failed to get matching services: 0x%x", result);
            return;
        }

        io_service_t service = IO_OBJECT_NULL;
        while ((service = IOIteratorNext(itreator)) != IO_OBJECT_NULL) {
            CFMutableDictionaryRef propertiesRef = NULL;
            const kern_return_t result = IORegistryEntryCreateCFProperties(service, &propertiesRef, CFAllocatorGetDefault(), 0);
            if (result != KERN_SUCCESS) {
                IOObjectRetain(service);
                continue;
            }

            NSMutableDictionary * const properties = (__bridge_transfer NSMutableDictionary *)propertiesRef;
            os_log_debug(OS_LOG_DEFAULT, "Found multitouch device: %{public}@", properties);

            // Use first actuation supported build-in, multitouch device, which should be a track pad.
            NSString * const productProperty = (NSString *)properties[@"Product"];
            NSNumber * const acutuationSupportedProperty = (NSNumber *)properties[@"ActuationSupported"];
            NSNumber * const mtBuildInProperty = (NSNumber *)properties[@"MT Built-In"];
            if (!(acutuationSupportedProperty.boolValue && mtBuildInProperty.boolValue)) {
                os_log_info(OS_LOG_DEFAULT, "Found not applicable multitouch device: %{public}@", productProperty);
                IOObjectRetain(service);
                continue;
            }

            NSNumber * const multitouchIDProperty = (NSNumber *)properties[@"Multitouch ID"];
            const UInt64 multitouchDeviceMultitouchID = multitouchIDProperty.longLongValue;
            const CFTypeRef actuatorRef = MTActuatorCreateFromDeviceID(multitouchDeviceMultitouchID);
            if (!actuatorRef) {
                os_log_info(OS_LOG_DEFAULT, "Fail to MTActuatorCreateFromDeviceID: 0x%llx multitouich device: %{public}@", multitouchDeviceMultitouchID, productProperty);
                IOObjectRetain(service);
                continue;
            }

            os_log_info(OS_LOG_DEFAULT, "Use MTActuatorCreateFromDeviceID: 0x%llx multitouich device: %{public}@", multitouchDeviceMultitouchID, productProperty);
            _actuatorRef = actuatorRef;
            self.lastKnownMultitouchDeviceMultitouchID = multitouchDeviceMultitouchID;

            IOObjectRelease(service);
            break;
        }
        IOObjectRelease(itreator);

        if (!_actuatorRef) {
            os_log_info(OS_LOG_DEFAULT, "Fail to any MTActuatorCreateFromDeviceID");
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
