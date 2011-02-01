//
//  AppController.m
//  Shadows
//
//  Created by Ruaridh Thomson on 13/05/2010.
//  Copyright 2010 Life Up North/Ruaridh Thomson. All rights reserved.
//
//	This software is distributed under licence. Use of this software
//	implies agreement with all terms and conditions of the accompanying
//	software licence.

#import "AppController.h"
#include <stdio.h>
#include <mach/mach.h>
#include <IOKit/IOKitLib.h>
#include "lmucommon.h"

static io_connect_t dataPort = 0;
static double updateInterval = 0.5;

@implementation AppController

- (id)init
{
	if (![super init]) {
		return nil;
	}
	
	return self;
}

- (void)awakeFromNib
{	
	if (![showAtStartup state]) {
		[welcome makeKeyAndOrderFront:self];
	}
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	//[statusItem setTitle:@"Shadows"];
	[statusItem setHighlightMode:YES];
	[statusItem setImage:[NSImage imageNamed:@"statusMenuIcon3"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"statusMenuIcon3Alt"]];
	[statusItem setMenu:statusMenu];
	
	KeyCombo comboLeft = { NSCommandKeyMask, 123 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"LeftSensorKeyCode"])
		comboLeft.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"LeftSensorKeyCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"LeftSensorKeyFlags"])
		comboLeft.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"LeftSensorKeyFlags"] intValue];
	
	KeyCombo comboRight = { NSCommandKeyMask, 124 };
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"RightSensorKeyCode"])
		comboRight.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"RightSensorKeyCode"] intValue];
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"RightSensorKeyFlags"])
		comboRight.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"RightSensorKeyFlags"] intValue];
	
	KeyCombo comboDouble = { NSCommandKeyMask, 49 };
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"DoubleSensorKeyCode"])
		comboDouble.code = [[[NSUserDefaults standardUserDefaults] objectForKey: @"DoubleSensorKeyCode"] intValue];
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"DoubleSensorKeyFlags"])
		comboDouble.flags = [[[NSUserDefaults standardUserDefaults] objectForKey: @"DoubleSensorKeyFlags"] intValue];
	 
	[leftSensorControl setDelegate:self];
	[rightSensorControl setDelegate:self];
	[doubleSensorControl setDelegate:self];
	
	[leftSensorControl setKeyCombo:comboLeft];
	[rightSensorControl setKeyCombo:comboRight];
	[doubleSensorControl setKeyCombo:comboDouble];
	
	[leftSensorControl setCanCaptureGlobalHotKeys:YES];
	[rightSensorControl setCanCaptureGlobalHotKeys:YES];
	[doubleSensorControl setCanCaptureGlobalHotKeys:YES];
	
	[leftSensorControl setAllowsKeyOnly:YES escapeKeysRecord:YES];
	[rightSensorControl setAllowsKeyOnly:YES escapeKeysRecord:YES];
	[doubleSensorControl setAllowsKeyOnly:YES escapeKeysRecord:NO];
	
	shadowSensitivity = [sensitivitySlider intValue];
	
	oldLeft = 0;
	oldRight = 0;
	
	[self startReading];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

- (void)startReading
{
	kern_return_t     kr;
	io_service_t      serviceObject;
	
	// Look up a registered IOService object whose class is AppleLMUController
	serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault,
												IOServiceMatching("AppleLMUController"));
	if (!serviceObject) {
		fprintf(stderr, "failed to find ambient light sensor\n");
		NSLog(@"Can't find ambient light sensor");
		exit(1);
	}
	
	// Create a connection to the IOService object
	kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
	IOObjectRelease(serviceObject);
	if (kr != KERN_SUCCESS) {
		mach_error("IOServiceOpen:", kr);
		NSLog(@"IOServiceOpen");
		exit(kr);
	}
	
	//setbuf(stdout, NULL);
	NSLog(@"Shadows Started - %8ld %8ld \n", 0L, 0L);
	
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(refreshTimer) userInfo:nil repeats:YES];
}

- (void)refreshTimer
{
	kern_return_t kr;
	uint32_t	scalarInputCount = 0;
	uint32_t	scalarOutputCount = 2;
	uint64_t	left = 0;
	uint64_t	right = 0;
	int64_t		doLeft = 0;
	int64_t		doRight = 0;
	
	//kr = IOConnectMethodScalarIScalarO(dataPort, kGetSensorReadingID, scalarInputCount, scalarOutputCount, &left, &right);
	//kr = IOConnectCallMethod(dataPort, kGetSensorReadingID, &left, scalarInputCount, nil, 0, &right, &scalarOutputCount, nil, 0);
	
	kr = IOConnectCallScalarMethod(dataPort, kGetSensorReadingID, &left, scalarInputCount, &right, &scalarOutputCount);
	
	/*
	 IOConnectCallScalarMethod(
	 mach_port_t	 connection,		// In
	 uint32_t	 selector,		// In
	 const uint64_t	*input,			// In
	 uint32_t	 inputCnt,		// In
	 uint64_t	*output,		// Out
	 uint32_t	*outputCnt)		// In/Out
	 AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER;
	 */
	
	int intLeft = (int)left;
	int intRight = (int)right;
	
	if (kr == KERN_SUCCESS) {
		//printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%8ld %8ld", left, right);
		//NSLog(@" New values: %8ld %d", intLeft, intRight);
		//NSLog(@" Old values: %8ld %d", oldLeft, oldRight);
		doRight = oldLeft - left - shadowSensitivity;
		doLeft = oldRight - right - shadowSensitivity;
		//NSLog(@" Old - New: %8ld %d \n", doLeft, doRight);
		
		if ((0 < doRight) && (0 < doLeft)) {
			//NSLog(@"--------- %i > 0 --- %i > 0 --------", doLeft, doRight);
			//NSLog(@"Perform Double Operation");
			[self performDoubleOperation];
			oldLeft = left;
			oldRight = right;
			return;
		}
		
		
		if (0 < doLeft) {
			//NSLog(@"--------- %8ld > 0 --------", doLeft);
			//NSLog(@"Perform Left Operation");
			[self performLeftOperation];
		}
		
		if (0 < doRight) {
			//NSLog(@"--------- %8ld > 0 --------", doRight);
			//NSLog(@"Perform Right Operation");
			[self performRightOperation]; 
		}
		oldLeft = left;
		oldRight = right;
		return;
	}
	
	if (kr == kIOReturnBusy)
		return;
	
	mach_error("I/O Kit error:", kr);
	exit(kr);
}

#pragma mark -
#pragma mark Sensor Operations

- (void)performLeftOperation
{
	NSLog(@"Performing left operation");
	CFRelease(CGEventCreate(NULL));
	
	KeyCombo theKeyCombo = [leftSensorControl keyCombo];
	
	CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	CGEventRef saveCommandDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, YES);
	CGEventSetFlags(saveCommandDown, (CGEventFlags)theKeyCombo.flags);
	//CGEventRef saveCommandUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, NO);
	//CGEventSetFlags(saveCommandUp, theKeyCombo.flags);
	
	CGEventPost(kCGHIDEventTap, saveCommandDown);
	//CGEventPost(kCGHIDEventTap, saveCommandUp);
	
	CFRelease(saveCommandDown);
	//CFRelease(saveCommandUp);
	CFRelease(source);
	
	[self releaseOperationWithKeycode:theKeyCombo.code flags:theKeyCombo.flags];
}

- (void)performRightOperation
{
	NSLog(@"Performing right operation");
	CFRelease(CGEventCreate(NULL));
	
	KeyCombo theKeyCombo = [rightSensorControl keyCombo];
	
	CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	CGEventRef saveCommandDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, YES);
	CGEventSetFlags(saveCommandDown, (CGEventFlags)theKeyCombo.flags);
	//CGEventRef saveCommandUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, NO);
	//CGEventSetFlags(saveCommandUp, theKeyCombo.flags);
	
	CGEventPost(kCGHIDEventTap, saveCommandDown);
	//CGEventPost(kCGHIDEventTap, saveCommandUp);
	
	CFRelease(saveCommandDown);
	//CFRelease(saveCommandUp);
	CFRelease(source);
	[self releaseOperationWithKeycode:theKeyCombo.code flags:theKeyCombo.flags];
}

- (void)performDoubleOperation
{
	NSLog(@"Performing double operation");
	CFRelease(CGEventCreate(NULL));
	
	KeyCombo theKeyCombo = [doubleSensorControl keyCombo];
	
	CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	CGEventRef saveCommandDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, YES);
	CGEventSetFlags(saveCommandDown, (CGEventFlags)theKeyCombo.flags);
	//CGEventRef saveCommandUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)theKeyCombo.code, NO);
	//CGEventSetFlags(saveCommandUp, theKeyCombo.flags);
	
	CGEventPost(kCGSessionEventTap, saveCommandDown);
	//CGEventPost(kCGAnnotatedSessionEventTap, saveCommandUp);
	
	CFRelease(saveCommandDown);
	//CFRelease(saveCommandUp);
	CFRelease(source);
	
	[self releaseOperationWithKeycode:theKeyCombo.code flags:theKeyCombo.flags];
}

// Note: As mentioned below, this is a roundabout way of releasing the flags of the keypress.
- (void)releaseOperationWithKeycode:(signed short)keyCode flags:(unsigned int)flags
{
	AXUIElementRef axSystemWideElement = AXUIElementCreateSystemWide();
	AXError err = AXUIElementPostKeyboardEvent(axSystemWideElement, 0, keyCode, NO);
	if (err != kAXErrorSuccess) {
		NSLog(@" Did not post key press!");
	}
	
	// Note: For some reason we need to manually release the flags of a KeyboardEvent this way.  It's easier doing the above.
	/*
	CFRelease(CGEventCreate(NULL));
	//CGEventSourceRef releaseSource = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	CGEventRef keysUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, NO);
	CGEventSetFlags(keysUp, (CGEventFlags)flags);
	CGEventSetType(keysUp, kCGEventKeyUp);
	
	CGEventPost(kCGSessionEventTap, keysUp);
	
	CFRelease(keysUp);
	 */
	//CFRelease(releaseSource);
	
	//CGPostKeyboardEvent(0, keyCode, NO);
}

#pragma mark -
#pragma mark ShortcutRecorder Delegates

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (aRecorder == leftSensorControl) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"LeftSensorKeyCode"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"LeftSensorKeyFlags"];
    } else if (aRecorder == rightSensorControl) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"RightSensorKeyCode"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"RightSensorKeyFlags"];
    } else if (aRecorder == doubleSensorControl) {
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.code] forKey: @"DoubleSensorKeyCode"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: newKeyCombo.flags] forKey: @"DoubleSensorKeyFlags"];
    }
	
    [[NSUserDefaults standardUserDefaults] synchronize];
}
	 
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason
{
	return NO;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)changeShadowSensitivity:(id)sender
{
	shadowSensitivity = [sensitivitySlider intValue];
}

- (IBAction)openURLLUNContact:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:lifeupnorth@me.com"]];
}

- (IBAction)openURLLifeUpNorth:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lifeupnorth.co.uk/"]];
}

@end
