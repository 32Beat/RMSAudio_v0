////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUnitPlatformIO
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSAudioUnitPlatformIO.h"


////////////////////////////////////////////////////////////////////////////////
#import "PCMAudioUtilities.h"

#if TARGET_OS_IPHONE
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_RemoteIO
#else
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_HALOutput
#endif

@interface RMSAudioUnitPlatformIO ()
{
	BOOL mAudioUnitIsRunning;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSAudioUnitPlatformIO
////////////////////////////////////////////////////////////////////////////////

+ (AudioComponentDescription) componentDescription
{
	return
	(AudioComponentDescription) {
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_PlatformIO,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0 };
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) enableInput:(BOOL)state
{ return AudioUnitEnableInput(mAudioUnit, state); }

- (OSStatus) enableOutput:(BOOL)state
{ return AudioUnitEnableOutput(mAudioUnit, state); }

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) startAudioUnit
{
	OSStatus result = AudioOutputUnitStart(mAudioUnit);
	if (result == noErr)
	{ mAudioUnitIsRunning = YES; }
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) stopAudioUnit
{
	OSStatus result = AudioOutputUnitStop(mAudioUnit);
	if (result == noErr)
	{ mAudioUnitIsRunning = NO; }
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) startRunning
{
	OSStatus result = noErr;
	
	result = [self initializeAudioUnit];
	if (result != noErr) return result;
	
	result = [self startAudioUnit];
	if (result != noErr) return result;
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) stopRunning
{
	OSStatus result = noErr;
	
	result = [self stopAudioUnit];
	if (result != noErr) return result;

	result = [self uninitializeAudioUnit];
	if (result != noErr) return result;
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
