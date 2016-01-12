////////////////////////////////////////////////////////////////////////////////
/*
	PCMAudioUtilities
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#include "PCMAudioUtilities.h"
#import <mach/mach_time.h>

////////////////////////////////////////////////////////////////////////////////

static bool g_pcmHostTimeInit = false;
static double g_pcmHostToSeconds = 1.0e-9;
static double g_pcmSecondsToHost = 1.0e+9;

////////////////////////////////////////////////////////////////////////////////

static void PCMHostTimeInit(void)
{
	mach_timebase_info_data_t timeInfo;
	mach_timebase_info(&timeInfo);
	if (timeInfo.numer && timeInfo.denom)
	{
		g_pcmHostToSeconds = 1.0e-9 * timeInfo.numer / timeInfo.denom;
		g_pcmSecondsToHost = 1.0e+9 * timeInfo.denom / timeInfo.numer;
		g_pcmHostTimeInit = true;
	}
}

////////////////////////////////////////////////////////////////////////////////

double PCMHostTimeToSeconds(double hostTime)
{
	if (g_pcmHostTimeInit == false)
	{ PCMHostTimeInit(); }
	return g_pcmHostToSeconds * hostTime;
}

////////////////////////////////////////////////////////////////////////////////

double PCMCurrentHostTimeInSeconds(void)
{ return PCMHostTimeToSeconds(mach_absolute_time()); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
#if TARGET_OS_DESKTOP

OSStatus PCMAudioGetDefaultInputDeviceID(AudioDeviceID *deviceID)
{
	static const AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultInputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	UInt32 size = sizeof(AudioDeviceID);
	return AudioObjectGetPropertyData(kAudioObjectSystemObject,
	&address, 0, nil, &size, deviceID);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioGetDefaultOutputDeviceID(AudioDeviceID *deviceID)
{
	static const AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	UInt32 size = sizeof(AudioDeviceID);
	return AudioObjectGetPropertyData(kAudioObjectSystemObject,
	&address, 0, nil, &size, deviceID);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioDeviceGetNominalSampleRate(AudioDeviceID deviceID, Float64 *sampleRatePtr)
{
	static const AudioObjectPropertyAddress address = {
		kAudioDevicePropertyNominalSampleRate,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	UInt32 size = sizeof(Float64);
	return AudioObjectGetPropertyData(deviceID,
	&address, 0, nil, &size, sampleRatePtr);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioDeviceSetNominalSampleRate(AudioDeviceID deviceID, Float64 sampleRate)
{
	static const AudioObjectPropertyAddress address = {
		kAudioDevicePropertyNominalSampleRate,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	UInt32 size = sizeof(Float64);
	return AudioObjectSetPropertyData(deviceID,
	&address, 0, nil, size, &sampleRate);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioDeviceGetSafetyOffset(AudioDeviceID deviceID, UInt32 *valuePtr)
{
	static const AudioObjectPropertyAddress address = {
		kAudioDevicePropertySafetyOffset,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };

	UInt32 size = sizeof(UInt32);
	return AudioObjectGetPropertyData
	(deviceID, &address, 0, nil, &size, valuePtr);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitSetDefaultInputDevice(AudioUnit audioUnit)
{
	AudioDeviceID deviceID = 0;
	OSStatus result = PCMAudioGetDefaultInputDeviceID(&deviceID);
	if (result != noErr) return result;
	
	return AudioUnitSetInputDevice(audioUnit, deviceID);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitSetInputDevice(AudioUnit audioUnit, AudioDeviceID deviceID)
{
	if (audioUnit == nil) return paramErr;

	if (deviceID == 0)
	{
		OSStatus result = PCMAudioGetDefaultInputDeviceID(&deviceID);
		if (result != noErr) return result;
	}

	return AudioUnitAttachDevice(audioUnit, deviceID);
}

////////////////////////////////////////////////////////////////////////////////
/*
	Attach an audio IO device to the audio unit. 
	If it is an output device, it will automatically be 
	attached to (bus 0, outputscope),
	If it is an input device, it will automatically be
	attached to (bus 1, inputscope),
*/

OSStatus AudioUnitAttachDevice(AudioUnit audioUnit, AudioDeviceID deviceID)
{
	if (audioUnit == nil) return paramErr;
//	if (deviceID == 0) return paramErr;
	
	UInt32 size = sizeof(deviceID);
	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
	kAudioUnitScope_Global, 0, &deviceID, size);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitGetCurrentDevice(AudioUnit audioUnit, AudioDeviceID *deviceID)
{
	if (audioUnit == nil) return paramErr;
	if (deviceID == nil) return paramErr;
	
	UInt32 size = sizeof(deviceID);
	return AudioUnitGetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
	kAudioUnitScope_Global, 0, deviceID, &size);
}

#endif

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
AudioUnit NewAudioUnitPlatformIOInstance(void)
{
	static const AudioComponentDescription info = {
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_PlatformIO,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0
	};
	
	return NewAudioUnitWithDescription(info);
}

////////////////////////////////////////////////////////////////////////////////
/*
AudioUnit NewAudioUnitHALInstance(void)
{
	static const AudioComponentDescription info = {
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_HALOutput,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0
	};
	
	return NewAudioUnitWithDescription(info);
}
*/
////////////////////////////////////////////////////////////////////////////////

AudioUnit NewAudioUnitWithDescription(AudioComponentDescription desc)
{
	AudioComponent component = AudioComponentFindNext(nil, &desc);
	if (component != nil)
	{
		AudioComponentInstance instance = nil;
		OSStatus result = AudioComponentInstanceNew(component, &instance);
		if (result == noErr)
		{
			return instance;
		}
		else
		NSLog(@"AudioComponentInstanceNew error: %d", result);
	}
	else
	NSLog(@"%@", @"AudioComponent not found!");
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitEnableInput(AudioUnit audioUnit, UInt32 state)
{
	if (audioUnit == nil) return paramErr;
	
	AudioUnitElement inputBus = 1;

	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
	kAudioUnitScope_Input, inputBus, &state, sizeof(UInt32));
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitEnableOutput(AudioUnit audioUnit, UInt32 state)
{
	if (audioUnit == nil) return paramErr;
	
	AudioUnitElement outputBus = 0;

	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
	kAudioUnitScope_Output, outputBus, &state, sizeof(UInt32));
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitSetInputCallback
(AudioUnit audioUnit, AURenderCallback renderProc, void *renderInfo)
{
	if (audioUnit == nil) return paramErr;
	if (renderProc == nil) return paramErr;
	
	AURenderCallbackStruct rcInfo = { renderProc, renderInfo };

	return AudioUnitSetProperty \
		(audioUnit, kAudioOutputUnitProperty_SetInputCallback, \
		kAudioUnitScope_Global, 0, &rcInfo, sizeof(AURenderCallbackStruct));
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitSetRenderCallback
(AudioUnit audioUnit, AURenderCallback renderProc, void *renderInfo)
{
	if (audioUnit == nil) return paramErr;
	if (renderProc == nil) return paramErr;

	AURenderCallbackStruct rcInfo = { renderProc, renderInfo };
	
	return AudioUnitSetProperty \
		(audioUnit, kAudioUnitProperty_SetRenderCallback, \
		kAudioUnitScope_Input, 0, &rcInfo, sizeof(AURenderCallbackStruct));
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitSetFormat(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat)
{
	if (audioUnit == nil) return paramErr;
	if (audioFormat == nil) return paramErr;

	return AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, \
	unitScope, streamIndex, audioFormat, sizeof(AudioStreamBasicDescription));
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitSetSourceFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetFormat(audioUnit, kAudioUnitScope_Input, streamIndex, audioFormat); }

OSStatus PCMAudioUnitSetResultFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetFormat(audioUnit, kAudioUnitScope_Output, streamIndex, audioFormat); }

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitSetInputSourceFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetSourceFormat(audioUnit, 1, audioFormat); }

OSStatus PCMAudioUnitSetInputResultFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetResultFormat(audioUnit, 1, audioFormat); }

OSStatus PCMAudioUnitSetOutputSourceFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetSourceFormat(audioUnit, 0, audioFormat); }

OSStatus PCMAudioUnitSetOutputResultFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetResultFormat(audioUnit, 0, audioFormat); }

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetFormat(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat)
{
	if (audioUnit == nil) return paramErr;
	if (audioFormat == nil) return paramErr;

	UInt32 size = sizeof(AudioStreamBasicDescription);
	return AudioUnitGetProperty
		(audioUnit, kAudioUnitProperty_StreamFormat, \
		unitScope, streamIndex, audioFormat, &size);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetSourceFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetFormat(audioUnit, kAudioUnitScope_Input, streamIndex, audioFormat); }

OSStatus PCMAudioUnitGetResultFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetFormat(audioUnit, kAudioUnitScope_Output, streamIndex, audioFormat); }

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetInputSourceFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetSourceFormat(audioUnit, 1, audioFormat); }

OSStatus PCMAudioUnitGetInputResultFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetResultFormat(audioUnit, 1, audioFormat); }

OSStatus PCMAudioUnitGetOutputSourceFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetSourceFormat(audioUnit, 0, audioFormat); }

OSStatus PCMAudioUnitGetOutputResultFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitGetResultFormat(audioUnit, 0, audioFormat); }

////////////////////////////////////////////////////////////////////////////////
/*
	InputCallback provides data to outputside of inputstream (bus 1)
	RenderCallback provides data to inputside of outputstream (bus 0)
	
	OutputSourceFormat refers to inputside of outputstream
	OutputResultFormat refers to outputside of outputstream
*/

OSStatus PCMAudioUnitSetInputCallbackFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetInputResultFormat(audioUnit, audioFormat); }

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitSetRenderCallbackFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat)
{ return PCMAudioUnitSetOutputSourceFormat(audioUnit, audioFormat); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetSampleRateAtIndex(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, Float64 *sampleRatePtr)
{
	if (audioUnit == nil) return paramErr;
	if (sampleRatePtr == nil) return paramErr;

	UInt32 size = sizeof(Float64);
	return AudioUnitGetProperty
		(audioUnit, kAudioUnitProperty_SampleRate, \
		unitScope, streamIndex, sampleRatePtr, &size);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetInputScopeSampleRateAtIndex(AudioUnit audioUnit,
AudioUnitElement streamIndex, Float64 *sampleRatePtr)
{ return PCMAudioUnitGetSampleRateAtIndex(audioUnit, kAudioUnitScope_Input, streamIndex, sampleRatePtr); }

OSStatus PCMAudioUnitGetOutputScopeSampleRateAtIndex(AudioUnit audioUnit,
AudioUnitElement streamIndex, Float64 *sampleRatePtr)
{ return PCMAudioUnitGetSampleRateAtIndex(audioUnit, kAudioUnitScope_Output, streamIndex, sampleRatePtr); }

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetMaximumFramesPerSlice(AudioUnit audioUnit, UInt32 *maxFrames)
{
	if (audioUnit == nil) return paramErr;
	if (maxFrames == nil) return paramErr;
	
	UInt32 size = sizeof(UInt32);
	return AudioUnitGetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice,
	kAudioUnitScope_Global, 0, maxFrames, &size);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitSetMaximumFramesPerSlice(AudioUnit audioUnit, UInt32 maxFrames)
{
	if (audioUnit == nil) return paramErr;
	
	UInt32 size = sizeof(UInt32);
	return AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice,
	kAudioUnitScope_Global, 0, &maxFrames, size);
}

////////////////////////////////////////////////////////////////////////////////


