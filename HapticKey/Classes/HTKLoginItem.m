//
//  HTKLoginItem.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 1/23/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKLoginItem.h"

@import CoreServices;
@import os.log;

NS_ASSUME_NONNULL_BEGIN

// NOTE: All `LSSharedFileList` API are deprecated.
// However, the alternative `SMLoginItemSetEnabled()` has unexpected behaviors when
// the system has multiple copy of bundle that has same bundle identifier.
// Also, it doesn't provide users to access the login item on System Preferences.
// As long as Apple doesn't remove these API, it would be better to use `LSSharedFileList` API instead.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static const OSStatus kUnknwonErrorStatus = -1;

static inline NSError *ErrorWithOSStatus(OSStatus status)
{
    return [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
}

static inline id _Nullable CreateLoginItemsFileList()
{
    return (__bridge_transfer id)LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
}

static inline void AddObserverToLoginItemsFileList(id fileList, LSSharedFileListChangedProcPtr callback, id _Nullable context)
{
    LSSharedFileListAddObserver((__bridge LSSharedFileListRef)fileList, CFRunLoopGetMain(), kCFRunLoopDefaultMode, callback, (__bridge void *)context);
}

static inline void RemoveObserverFromLoginItemsFileList(id fileList, LSSharedFileListChangedProcPtr callback, id _Nullable context)
{
    LSSharedFileListRemoveObserver((__bridge LSSharedFileListRef)fileList, CFRunLoopGetMain(), kCFRunLoopDefaultMode, callback, (__bridge void *)context);
}

static id _Nullable AddFileListItemAtPathToLoginItemsFileList(NSString *path, id fileList, NSError * _Nullable * _Nullable outError)
{
    NSURL * const url = [NSURL fileURLWithPath:path];

    id fileListItem = (__bridge_transfer id)LSSharedFileListInsertItemURL((__bridge LSSharedFileListRef)fileList, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)url, NULL, NULL);
    if (!fileListItem) {
        if (outError) {
            *outError = ErrorWithOSStatus(kUnknwonErrorStatus);
        }
    }
    return fileListItem;
}

static void RemoveFileListItemFromLoginItems(id fileListItem, id fileList, NSError * _Nullable * _Nullable outError)
{
    const OSStatus status = LSSharedFileListItemRemove((__bridge LSSharedFileListRef)fileList, (__bridge LSSharedFileListItemRef)fileListItem);
    if (status != noErr) {
        if (outError) {
            *outError = ErrorWithOSStatus(status);
        }
    }
}

static inline UInt32 GetFileListSeed(id fileList)
{
    return LSSharedFileListGetSeedValue((__bridge LSSharedFileListRef)fileList);
}

static NSArray * _Nullable CaptureFileListSnapshot(id fileList, UInt32 * _Nullable outSeed, NSError * _Nullable * _Nullable outError)
{
    NSArray * const fileListSnapshot = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot((__bridge LSSharedFileListRef)fileList, outSeed);
    if (!fileListSnapshot) {
        if (outError) {
            *outError = ErrorWithOSStatus(kUnknwonErrorStatus);
        }
    }
    return fileListSnapshot;
}

static id _Nullable FindFileListItemAtPathInFileListSnapshot(NSString *path, NSArray *fileListSnapshot, NSError * _Nullable * _Nullable outError)
{
    NSURL * const url = [NSURL fileURLWithPath:path];
    for (id fileListItem in fileListSnapshot) {
        static const UInt32 flags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef fileListItemURLRef = NULL;
        const OSStatus status = LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)fileListItem, flags, &fileListItemURLRef, NULL);
        NSURL * const fileListItemURL = (__bridge_transfer NSURL *)fileListItemURLRef;
        if (status != noErr) {
            if (outError) {
                *outError = ErrorWithOSStatus(status);
            }
            return nil;
        }

        if ([fileListItemURL isEqualTo:url]) {
            return fileListItem;
        }
    }
    return nil;
}

// MARK: -

@interface HTKLoginItem ()

- (void)_htk_main_fileListDidChange;

@end

static void HTKLoginItemFileListDidChange(LSSharedFileListRef fileList, void * _Nullable context)
{
    @autoreleasepool {
        HTKLoginItem *loginItem = (__bridge HTKLoginItem *)context;
        [loginItem _htk_main_fileListDidChange];
    }
}

static NSString * const kBackgroundItemsChangeNotification = @"com.apple.private.BackgroundItemsChangeNotification";

@interface HTKLoginItem ()

@property (nonatomic, readonly) id fileList;

@property (nonatomic, readonly) UInt32 seed;
@property (nonatomic, readonly, nullable) id fileListItem;

@end

@implementation HTKLoginItem

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        _path = [path copy];

        id const fileList = CreateLoginItemsFileList();
        if (!fileList) {
            os_log_error(OS_LOG_DEFAULT, "Fail to create login items.");
            return nil;
        }
        _fileList = fileList;

        // `LSSharedFileList` is using `NSDistributedNotificationCenter` to update the file list and when it's updated,
        // it set new `seed` (which is actually `arc4random` number) then calls registered observer callback by using
        // `CFRunLoopPerformBlock` asynchronously.
        // To make this works, the application needs to be able to always receive the notification from
        // `NSDistributedNotificationCenter` and also run `CFRunLoop` in specific mode to call the observer callback.
        // However, `NSApplication` is automatically suspend `NSDistributedNotificationCenter` when the application is
        // being inactive, that prevents LSSharedFileList implementation to update the file list.
        // Especially the application that is `LSUIElement` like this application, is always inactive, the notification
        // is not sent to `LSSharedFileList` always.
        // To workaround this behavior, add an arbitrary notification observer with `NSNotificationSuspensionBehaviorDeliverImmediately`
        // that ignores `NSDistributedNotificationCenter` suspended.
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(_htk_notification_backgroundItemDidChange:) name:kBackgroundItemsChangeNotification object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

        AddObserverToLoginItemsFileList(_fileList, HTKLoginItemFileListDidChange, self);

        [self _htk_main_update];
    }
    return self;
}

- (void)dealloc
{
    RemoveObserverFromLoginItemsFileList(self.fileList, HTKLoginItemFileListDidChange, self);
}

// MARK: - Notifications

- (void)_htk_notification_backgroundItemDidChange:(NSNotification *)notification
{
    // Nothing to do here.
    // See the comment in the initializer.
}

// MARK: - Callback

- (void)_htk_main_fileListDidChange
{
    [self _htk_main_updateIfNeeded];

    id<HTKLoginItemDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(loginItemDidChange:)]) {
        [delegate loginItemDidChange:self];
    }
}

- (void)_htk_main_updateIfNeeded
{
    UInt32 seed = GetFileListSeed(self.fileList);
    if (self.seed != seed) {
        [self _htk_main_update];
    }
}

- (void)_htk_main_update
{
    UInt32 seed;
    NSError *error;
    NSArray * const snapshot = CaptureFileListSnapshot(self.fileList, &seed, &error);
    if (error) {
        os_log_error(OS_LOG_DEFAULT, "Fail to capture login items snapshot code: %ld", (long)error.code);
        return;
    }
    id const fileListItem = FindFileListItemAtPathInFileListSnapshot(self.path, snapshot, &error);
    if (error) {
        os_log_error(OS_LOG_DEFAULT, "Fail to find login item at path: %{public}@ code: %ld", self.path, (long)error.code);
        return;
    }
    [self _htk_main_setFileListItem:fileListItem seed:seed];
}

- (void)_htk_main_setFileListItem:(id)fileListItem seed:(UInt32)seed
{
    os_log_info(OS_LOG_DEFAULT, "Update login items seed: %lu %lu login item: %p %p", (unsigned long)self.seed, (unsigned long)seed, self.fileListItem, fileListItem);

    _fileListItem = fileListItem;
    _seed = seed;
}

// MARK: - Properties

- (BOOL)isEnabled
{
    [self _htk_main_updateIfNeeded];

    return self.fileListItem != nil;
}

- (void)setEnabled:(BOOL)enabled
{
    if ([self isEnabled] != enabled) {
        NSError *error;
        if (enabled) {
            AddFileListItemAtPathToLoginItemsFileList(self.path, self.fileList, &error);
            if (error) {
                os_log_error(OS_LOG_DEFAULT, "Fail to add login item at path: %{public}@ code: %ld", self.path, (long)error.code);
                return;
            }
            os_log_info(OS_LOG_DEFAULT, "Add login item at path: %{public}@", self.path);
        } else {
            RemoveFileListItemFromLoginItems(self.fileListItem, self.fileList, &error);
            if (error) {
                os_log_error(OS_LOG_DEFAULT, "Fail to remove login item at path: %{public}@ code: %ld", self.path, (long)error.code);
                return;
            }
            os_log_info(OS_LOG_DEFAULT, "Remove login item at path: %{public}@", self.path);
        }
    }
}

@end

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
