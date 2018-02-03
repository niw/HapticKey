//
//  HTKSoundMenu.m
//  HapticKey
//
//  Created by Chris Ballinger on 2/2/18.
//  Copyright © 2018 Yoshimasa Niwa. All rights reserved.
//

#import "HTKSoundMenu.h"
#import "HTKSounds.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HTKFingerDirection) {
    HTKFingerDirectionUp,
    HTKFingerDirectionDown
};

@interface NSView (Constranits)
- (void)htk_pinToView:(NSView *)view edge:(NSLayoutAttribute)edge offset:(CGFloat)offset;
- (void)htk_pinToView:(NSView *)view edge:(NSLayoutAttribute)attribute;
- (void)htk_pinAllEdgesToView:(NSView *)view;
@end

@interface HTKSoundMenu()

/// all menu items in soundSubmenu
//@property (nonatomic, readonly) NSArray<NSMenuItem*> *allMenuItems;
/// menu items corresponding to sound files on disk
@property (nonatomic, readonly) NSArray<NSMenuItem*> *soundFileMenuItems;
@property (nonatomic, readonly) NSSlider *volumeSlider;

@end

@implementation HTKSoundMenu

// MARK: - Init

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)initWithSounds:(HTKSounds *)sounds
{
    NSParameterAssert(sounds);
    if (self = [super init]) {
        _sounds = sounds;
        _soundSubmenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Sound", @"label for sound submenu")];
        _volumeSlider = [NSSlider sliderWithTarget:self action:@selector(volumeSliderValueChanged:)];
        _volumeSlider.translatesAutoresizingMaskIntoConstraints = NO;
        [self refreshMenuItems];
    }
    return self;
}

// MARK: Public Methods

- (void) refreshMenuItems {
    [self.soundSubmenu removeAllItems];
    [self addSoundSubmenuItems];
    [self updateVolumeSlider];
}

// MARK: UI Actions

- (void) openSoundDirectoryInFinder:(NSMenuItem*)sender {
    [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:self.sounds.path]];
}

- (void) soundItemSelected:(NSMenuItem*)sender {
    HTKFingerDirection fingerDirection = sender.tag;
    NSString *soundFilePath = sender.representedObject;
    
    switch (fingerDirection) {
        case HTKFingerDirectionUp:
            HTKSounds.fingerUpFilePath = soundFilePath;
            [self.sounds reloadFingerUp];
            [self.sounds playFingerUp];
            break;
        case HTKFingerDirectionDown:
            HTKSounds.fingerDownFilePath = soundFilePath;
            [self.sounds reloadFingerDown];
            [self.sounds playFingerDown];
            break;
    }
    [self updateStateForSoundMenuItems];
}

- (void) volumeSliderValueChanged:(NSSlider*)sender {
    HTKSounds.desiredVolume = sender.floatValue;
    [self.sounds updateVolume];
    // preview volume level
    if (HTKSounds.fingerDownFilePath) {
        [self.sounds playFingerDown];
    } else if (HTKSounds.fingerUpFilePath) {
        [self.sounds playFingerUp];
    }
}

// MARK: Private Methods

- (void) updateVolumeSlider {
    float value = HTKSounds.desiredVolume;
    self.volumeSlider.floatValue = value;
}

/// adds/removes checkmarks to the sound menu items that were chosen by the user
- (void) updateStateForSoundMenuItems {
    [self.soundFileMenuItems enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setStateForSoundMenuItem:obj];
    }];
}

- (NSMenuItem *) menuItemForSoundFilePath:(nullable NSString*)soundFilePath fingerDirection:(HTKFingerDirection)fingerDirection  {
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = soundFilePath;
    menuItem.tag = fingerDirection;
    
    NSString *title = soundFilePath.lastPathComponent.stringByDeletingPathExtension;
    if (!title) {
        title = NSLocalizedString(@"None", "no sound menu item selected");
    }
    
    if ([soundFilePath isEqualToString:HTKSounds.defaultUpFilePath] ||
        [soundFilePath isEqualToString:HTKSounds.defaultDownFilePath]) {
        NSString *defaultString = NSLocalizedString(@"Default", @"string for default sound");
        title = [NSString stringWithFormat:@"%@ %@", defaultString, title];
    }
    menuItem.title = title;

    [self setStateForSoundMenuItem:menuItem];
    
    menuItem.target = self;
    menuItem.action = @selector(soundItemSelected:);
    return menuItem;
}

- (void) setStateForSoundMenuItem:(NSMenuItem*)menuItem {
    NSString *soundFilePath = menuItem.representedObject;
    HTKFingerDirection direction = menuItem.tag;
    
    NSString *upPath = HTKSounds.fingerUpFilePath;
    NSString *downPath = HTKSounds.fingerDownFilePath;
    
    switch (direction) {
        case HTKFingerDirectionUp:
            if ((soundFilePath && upPath && [soundFilePath isEqualToString:HTKSounds.fingerUpFilePath]) ||
                (soundFilePath == nil && upPath == nil) ) {
                menuItem.state = NSOnState;
            } else {
                menuItem.state = NSOffState;
            }
            break;
        case HTKFingerDirectionDown:
            if ((soundFilePath && downPath && [soundFilePath isEqualToString:downPath]) ||
                 (soundFilePath == nil && downPath == nil)) {
                menuItem.state = NSOnState;
            } else {
                menuItem.state = NSOffState;

            }
            break;
    }
}

- (void) addSoundSubmenuItems {
    NSArray<NSMenuItem*> *menuItems = self.allMenuItems;
    [menuItems enumerateObjectsUsingBlock:^(NSMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.soundSubmenu addItem:obj];
    }];
}

- (NSArray<NSMenuItem*>*) generateSoundMenuItemsForDirection:(HTKFingerDirection)direction {
    NSMutableArray<NSMenuItem*>* items = [NSMutableArray array];
    [self.sounds.allSoundFiles enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMenuItem *item = [self menuItemForSoundFilePath:obj.path fingerDirection:direction];
        [items addObject:item];
    }];
    NSMenuItem *noneItem = [self menuItemForSoundFilePath:nil fingerDirection:direction];
    [items addObject:noneItem];
    return items;
}

- (NSArray<NSMenuItem*>*) allMenuItems {
    
    
    NSMutableArray<NSMenuItem*> *menuItems = [NSMutableArray array];
    
    // Finger Down
    
    NSMenuItem *fingerDownLabel = [[NSMenuItem alloc] init];
    fingerDownLabel.title = NSLocalizedString(@"Finger Down", @"section label for finger down settings");
    fingerDownLabel.enabled = NO;
    [menuItems addObject:fingerDownLabel];
    
    NSArray<NSMenuItem*> *downItems = [self generateSoundMenuItemsForDirection:HTKFingerDirectionDown];
    [menuItems addObjectsFromArray:downItems];
    
    // Finger Up
    [menuItems addObject:NSMenuItem.separatorItem];
    
    NSMenuItem *fingerUpLabel = [[NSMenuItem alloc] init];
    fingerUpLabel.title = NSLocalizedString(@"Finger Up", @"section label for finger up settings");
    fingerUpLabel.enabled = NO;
    [menuItems addObject:fingerUpLabel];
    
    NSArray<NSMenuItem*> *upItems = [self generateSoundMenuItemsForDirection:HTKFingerDirectionUp];
    [menuItems addObjectsFromArray:upItems];
    
    // Volume Control
    [menuItems addObject:NSMenuItem.separatorItem];

    NSMenuItem *volumeLabel = [[NSMenuItem alloc] init];
    volumeLabel.title = NSLocalizedString(@"Volume", @"section label for sound effect volume setting");
    volumeLabel.enabled = NO;
    [menuItems addObject:volumeLabel];
    
    NSMenuItem *volumeItem = [[NSMenuItem alloc] init];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 19)];
    [view addSubview:self.volumeSlider];
    [view htk_pinToView:self.volumeSlider edge:NSLayoutAttributeLeading offset:-20];
    [view htk_pinToView:self.volumeSlider edge:NSLayoutAttributeTop offset:0];
    [view htk_pinToView:self.volumeSlider edge:NSLayoutAttributeBottom offset:0];
    [view htk_pinToView:self.volumeSlider edge:NSLayoutAttributeTrailing offset:0];
    volumeItem.view = view;
    [menuItems addObject:volumeItem];
    
    // Add Sounds...
    BOOL showCustom = YES;
    if (showCustom) {
        [menuItems addObject:NSMenuItem.separatorItem];
        
        NSMenuItem *addSounds = [[NSMenuItem alloc] init];
        addSounds.title = NSLocalizedString(@"Add Sounds...", @"menu item for adding custom sounds");
        addSounds.action = @selector(openSoundDirectoryInFinder:);
        addSounds.target = self;
        [menuItems addObject:addSounds];
    }
    
    // store sounds separately so we can toggle them
    _soundFileMenuItems = [upItems arrayByAddingObjectsFromArray:downItems];
    
    return menuItems;
}

@end

// MARK: - View Constraints

@implementation NSView (Constranits)

- (void)htk_pinToView:(NSView *)view edge:(NSLayoutAttribute)edge {
    [self htk_pinToView:view edge:edge offset:0.0];
}

- (void)htk_pinToView:(NSView *)view edge:(NSLayoutAttribute)edge offset:(CGFloat)offset
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:edge
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view
                                                     attribute:edge
                                                    multiplier:1.0f
                                                      constant:offset]];
}

- (void)htk_pinAllEdgesToView:(NSView *)view
{
    [self htk_pinToView:view edge:NSLayoutAttributeBottom];
    [self htk_pinToView:view edge:NSLayoutAttributeTop];
    [self htk_pinToView:view edge:NSLayoutAttributeLeading];
    [self htk_pinToView:view edge:NSLayoutAttributeTrailing];
}
@end

NS_ASSUME_NONNULL_END
