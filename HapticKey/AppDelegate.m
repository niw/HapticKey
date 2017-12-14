//
//  AppDelegate.m
//  HapticKey
//
//  Created by Yoshimasa Niwa on 11/30/17.
//  Copyright © 2017 Yoshimasa Niwa. All rights reserved.
//

#import "AppDelegate.h"
#import "HTKEventTap.h"
#import "HTKMultitouchActuator.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate () <HTKEventTapDelegate>

@property (nonatomic, nullable) NSStatusItem *statusItem;
@property (nonatomic, nullable) HTKEventTap *eventTap;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _main_loadStatusItem];

    if (AXIsProcessTrusted()) {
        const CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
        HTKEventTap * const tap = [[HTKEventTap alloc] initWithEventMask:eventMask];
        tap.delegate = self;
        tap.enabled = YES;
        self.eventTap = tap;
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

- (void)_main_loadStatusItem
{
    NSStatusBar * const statusBar = [NSStatusBar systemStatusBar];
    NSStatusItem * const statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];

    NSImage * const statusItemImage = [NSImage imageNamed:@"StatusItem"];
    statusItemImage.template = YES;
    [statusItem setImage:statusItemImage];

    NSMenu * const statusMenu = [[NSMenu alloc] init];

    NSMenuItem * const quitMenuItem = [[NSMenuItem alloc] init];
    quitMenuItem.title = @"Quit";
    quitMenuItem.keyEquivalent = @"q";
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    quitMenuItem.action = @selector(terminate:);
    [statusMenu addItem:quitMenuItem];

    [statusItem setMenu:statusMenu];

    self.statusItem = statusItem;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return NO;
}

// MARK: - HTKEventTapDelegate

// A lsit of key code ESC and F1 to F12.
static int64_t const kEscAndFunctionKeycodes[] = {
    53, // ESC
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111 // F1 to F12
};
static const NSUInteger kNumberOfEscAndFunctionKeycodes = sizeof (kEscAndFunctionKeycodes) / sizeof (int64_t);
static const int64_t kTouchbarKeyboardType = 198;

- (void)eventTap:(HTKEventTap *)eventTap didTapEvent:(NSEvent *)event
{
    const int64_t keyboardType = CGEventGetIntegerValueField(event.CGEvent, kCGKeyboardEventKeyboardType);
    if (keyboardType == kTouchbarKeyboardType && !event.ARepeat) {
        for (NSUInteger index = 0; index < kNumberOfEscAndFunctionKeycodes; index += 1) {
            if (kEscAndFunctionKeycodes[index] == event.keyCode) {
                switch (event.type) {
                    case NSEventTypeKeyDown:
                        [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:2.0];
                        break;
                    case NSEventTypeKeyUp:
                        [[HTKMultitouchActuator sharedActuator] actuateActuationID:6 unknown1:0 unknown2:0.0 unknown3:0.0];
                        break;
                    default:
                        // Should not reach here.
                        break;
                }
                break;
            }
        }
    }
}

@end

NS_ASSUME_NONNULL_END
