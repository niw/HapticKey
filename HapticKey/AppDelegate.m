//
//  AppDelegate.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 11/30/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "AppDelegate.h"
#import "HTKMultitouchActuator.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate ()

@property (nonatomic, nullable) NSStatusItem *statusItem;
@property (nonatomic, nullable) IBOutlet NSMenu *statusMenu;

@end

@implementation AppDelegate

// A lsit of key code ESC and F1 to F12.
static int64_t const kEscAndFunctionKeycodes[] = {
    53, // ESC
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111 // F1 to F12
};
static const NSUInteger kNumberOfEscAndFunctionKeycodes = sizeof (kEscAndFunctionKeycodes) / sizeof (int64_t);
static const int64_t kTouchbarKeyboardType = 198;

static CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type,  CGEventRef event, void *refcon) {
    const int64_t keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    const int64_t autorepeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
    const int64_t keyboardType = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);

    if (keyboardType == kTouchbarKeyboardType && autorepeat != 1) {
        for (NSUInteger index = 0; index < kNumberOfEscAndFunctionKeycodes; index += 1) {
            if (kEscAndFunctionKeycodes[index] == keycode) {
                switch (type) {
                    case kCGEventKeyDown:
                        [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:2.0];
                        break;
                    case kCGEventKeyUp:
                        [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:0.0];
                        break;
                    default:
                        break;
                }
                break;
            }
        }
    }
    return event;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSStatusBar * const statusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    [self.statusItem setImage:statusItemImage];
    [self.statusItem setMenu:self.statusMenu];

    if (AXIsProcessTrusted()) {
        const CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, CGEventMaskBit(kCGEventKeyDown)|CGEventMaskBit(kCGEventKeyUp), eventCallback, NULL);
        if (eventTap) {
            const CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
            CGEventTapEnable(eventTap, true);
        }
    } else {
        NSAlert * const alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        alert.messageText = @"Please allow to use Accessibility on Privacy settings in the System Preferences.";
        alert.informativeText = @"To listen keyboard events, the application needs to have a permission to use Accessibility.";
        alert.alertStyle = NSAlertStyleCritical;
        // Surprisingly, this is a blocking call.
        [alert runModal];
        [[NSApplication sharedApplication] terminate:nil];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

@end

NS_ASSUME_NONNULL_END
