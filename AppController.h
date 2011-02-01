//
//  AppController.h
//  Shadows
//
//  Created by Ruaridh Thomson on 13/05/2010.
//  Copyright 2010 Life Up North/Ruaridh Thomson. All rights reserved.
//
//	This software is distributed under licence. Use of this software
//	implies agreement with all terms and conditions of the accompanying
//	software licence.

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <ShortcutRecorder/SRRecorderControl.h>

@class SRRecorderControl;
// For some reason it doesn't want to compile if we don't do the above three ShortcutRecorder references.

@interface AppController : NSObject {
	uint64_t	oldLeft;
	uint64_t	oldRight;
	
	uint64_t	shadowSensitivity;
	IBOutlet NSSlider *sensitivitySlider;
	
	IBOutlet NSPanel *preferencesPanel;
	IBOutlet NSMenuItem *startStopButton;

	NSTimer *refreshTimer;
	
	IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
	
	IBOutlet SRRecorderControl *leftSensorControl;
	IBOutlet SRRecorderControl *rightSensorControl;
	IBOutlet SRRecorderControl *doubleSensorControl;
	
	IBOutlet NSButton *showAtStartup;
	IBOutlet NSWindow *welcome;
}

- (void)startReading;
- (void)refreshTimer;

- (void)performLeftOperation;
- (void)performRightOperation;
- (void)performDoubleOperation;
- (void)releaseOperationWithKeycode:(signed short)keyCode flags:(unsigned int)flags;

- (IBAction)openURLLifeUpNorth:(id)sender;
- (IBAction)openURLLUNContact:(id)sender;

- (IBAction)changeShadowSensitivity:(id)sender;

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;

@end
