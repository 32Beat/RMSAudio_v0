////////////////////////////////////////////////////////////////////////////////
/*
	PCMAudioUtilities
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef PCMAudioUtilities_h
#define PCMAudioUtilities_h

#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>
#include <Foundation/Foundation.h>
#include "RMSAudioUtilities.h"


/*
	
*/
#define TARGET_OS_DESKTOP (!TARGET_OS_IPHONE)

#if TARGET_OS_IPHONE
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_RemoteIO
#else
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_HALOutput
#endif


double PCMHostTimeToSeconds(double hostTime);
double PCMCurrentHostTimeInSeconds(void);

#if TARGET_OS_DESKTOP
OSStatus PCMAudioGetDefaultInputDeviceID(AudioDeviceID *deviceID);
OSStatus PCMAudioGetDefaultOutputDeviceID(AudioDeviceID *deviceID);
OSStatus PCMAudioDeviceSetNominalSampleRate(AudioDeviceID deviceID, Float64 sampleRate);
OSStatus PCMAudioDeviceGetNominalSampleRate(AudioDeviceID deviceID, Float64 *sampleRatePtr);
OSStatus PCMAudioDeviceGetSafetyOffset(AudioDeviceID deviceID, UInt32 *valuePtr);

OSStatus AudioUnitSetInputDevice(AudioUnit audioUnit, AudioDeviceID deviceID);
OSStatus AudioUnitAttachDevice(AudioUnit audioUnit, AudioDeviceID deviceID);
OSStatus AudioUnitGetCurrentDevice(AudioUnit audioUnit, AudioDeviceID *deviceID);
#endif

AudioUnit NewAudioUnitPlatformIOInstance(void);
AudioUnit NewAudioUnitWithDescription(AudioComponentDescription desc);
OSStatus AudioUnitEnableInput(AudioUnit audioUnit, UInt32 state);
OSStatus AudioUnitEnableOutput(AudioUnit audioUnit, UInt32 state);
OSStatus AudioUnitSetDefaultInputDevice(AudioUnit audioUnit);

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetFormat(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitGetSourceFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitGetResultFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitGetInputSourceFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitGetInputResultFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitGetOutputSourceFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitGetOutputResultFormat(AudioUnit audioUnit, AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitSetFormat(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitSetSourceFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitSetResultFormat(AudioUnit audioUnit,
AudioUnitElement streamIndex, const AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitSetInputSourceFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitSetInputResultFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitSetOutputSourceFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitSetOutputResultFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);

OSStatus PCMAudioUnitSetInputCallbackFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);
OSStatus PCMAudioUnitSetRenderCallbackFormat(AudioUnit audioUnit, const AudioStreamBasicDescription *audioFormat);

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioUnitSetInputCallback
(AudioUnit audioUnit, AURenderCallback renderProc, void *renderInfo);
OSStatus AudioUnitSetRenderCallback
(AudioUnit audioUnit, AURenderCallback renderProc, void *renderInfo);

////////////////////////////////////////////////////////////////////////////////

OSStatus PCMAudioUnitGetSampleRateAtIndex(AudioUnit audioUnit, AudioUnitScope unitScope,
AudioUnitElement streamIndex, Float64 *sampleRatePtr);
OSStatus PCMAudioUnitGetInputScopeSampleRateAtIndex(AudioUnit audioUnit,
AudioUnitElement streamIndex, Float64 *sampleRatePtr);
OSStatus PCMAudioUnitGetOutputScopeSampleRateAtIndex(AudioUnit audioUnit,
AudioUnitElement streamIndex, Float64 *sampleRatePtr);

OSStatus PCMAudioUnitGetInputSourceSampleRate(AudioUnit audioUnit, Float64 *sampleRatePtr);

OSStatus PCMAudioUnitGetMaximumFramesPerSlice(AudioUnit audioUnit, UInt32 *maxFrames);
OSStatus PCMAudioUnitSetMaximumFramesPerSlice(AudioUnit audioUnit, UInt32 maxFrames);

#endif // PCMAudioUtilities_h






