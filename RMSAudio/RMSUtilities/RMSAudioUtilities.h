////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUtilities
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <Accelerate/Accelerate.h>

#ifndef RMSAudioUtilities_h
#define RMSAudioUtilities_h

#ifndef __MACERRORS__
static const OSStatus paramErr = -50;
static const OSStatus memFullErr = -108;
#endif


double RMSCurrentHostTimeInSeconds(void);
double RMSHostTimeToSeconds(double hostTime);

typedef struct RMSStereoBufferList
{
    UInt32      bufferCount;
    AudioBuffer buffer[2];
}
RMSStereoBufferList;

typedef RMSStereoBufferList RMSStereoBufferList32f;

static OSStatus AudioBufferPrepare32f(AudioBuffer *buffer, UInt32 channelCount, UInt32 frameCount)
{
	buffer->mNumberChannels = channelCount;
	buffer->mDataByteSize = channelCount * frameCount * sizeof(Float32);
	buffer->mData = malloc(buffer->mDataByteSize);
	
	return buffer->mData ? noErr : memFullErr;
}

static OSStatus RMSStereoBufferListPrepare32f(RMSStereoBufferList32f *stereoBuffer, UInt32 frameCount)
{
	stereoBuffer->bufferCount = 2;
	return
	AudioBufferPrepare32f(&stereoBuffer->buffer[0], 1, frameCount)||
	AudioBufferPrepare32f(&stereoBuffer->buffer[1], 1, frameCount);
}


static inline void AudioBufferList_ClearBuffers(AudioBufferList *bufferList)
{
	for (UInt32 n=bufferList->mNumberBuffers; n!=0; n--)
	{ vDSP_vclr(bufferList->mBuffers[n-1].mData, 1, bufferList->mBuffers[n-1].mDataByteSize>>2); }
}

static inline void AudioBufferList_ClearFrames(AudioBufferList *bufferList, UInt32 frameCount)
{
	UInt32 n=bufferList->mNumberBuffers;
	while (n != 0)
	{
		n -= 1;
		bufferList->mBuffers[n].mDataByteSize = frameCount<<2;
		vDSP_vclr(bufferList->mBuffers[n].mData, 1, frameCount);
	}
}


static inline void PCM_InterpolateStereo1(
	float *srcPtrL, float *srcPtrR, double srcOffset, double srcStep,
	float *dstPtrL, float *dstPtrR, UInt32 n)
{
	UInt32 srcIndex = srcOffset;
	UInt32 dstIndex = 0;
	
	float L1 = srcPtrL[srcIndex];
	float R1 = srcPtrR[srcIndex];
	srcIndex += 1;
	float L2 = srcPtrL[srcIndex];
	float R2 = srcPtrR[srcIndex];
	srcIndex += 1;

	srcOffset -= srcIndex;
	
	while (n != 0)
	{
		n -= 1;

		dstPtrL[dstIndex] = L1 + srcOffset * (L2 - L1);
		dstPtrR[dstIndex] = R1 + srcOffset * (R2 - R1);
		
		srcOffset += srcStep;
		if (srcOffset >= 1.0)
		{
			srcOffset -= 1.0;
			L1 = L2;
			R1 = R2;
			L2 = srcPtrL[srcIndex];
			R2 = srcPtrR[srcIndex];
			srcIndex += 1;
		}
		dstIndex += 1;
	}
}



static inline void PCM_InterpolateStereo(
	float *srcPtrL, float *srcPtrR, double srcR,
	float *dstPtrL, float *dstPtrR, double dstR, UInt32 n)
{
	double srcSum = 0;
	double srcStep = srcR / dstR;
	
	UInt32 srcIndex = 0;
	UInt32 dstIndex = 0;
	
	while (n != 0)
	{
		n -= 1;
		dstPtrL[dstIndex] = srcPtrL[srcIndex];
		dstPtrR[dstIndex] = srcPtrR[srcIndex];
		
		srcSum += srcStep;
		if (srcSum >= 1.0)
		{ srcIndex += 1; srcSum -= 1.0; }
		dstIndex += 1;
	}
}

static inline void AudioBufferList_InterpolateBuffers
(const AudioBufferList *srcListPtr, double srcR,
		AudioBufferList *dstListPtr, double dstR, UInt32 frameCount)
{
	PCM_InterpolateStereo(
		srcListPtr->mBuffers[0].mData, srcListPtr->mBuffers[1].mData, srcR,
		dstListPtr->mBuffers[0].mData, dstListPtr->mBuffers[1].mData, dstR, frameCount);
}



static inline void PCM_CopyStereo(
	float *srcPtrL, float *srcPtrR,
	float *dstPtrL, float *dstPtrR, UInt32 n)
{
	while (n != 0)
	{
		n -= 1;
		dstPtrL[n] = srcPtrL[n];
		dstPtrR[n] = srcPtrR[n];
	}
}

static inline void AudioBufferList_CopyBuffers
(const AudioBufferList *srcListPtr, AudioBufferList *dstListPtr, UInt32 frameCount)
{
	PCM_CopyStereo(
		srcListPtr->mBuffers[0].mData, srcListPtr->mBuffers[1].mData,
		dstListPtr->mBuffers[0].mData, dstListPtr->mBuffers[1].mData, frameCount);
}


static inline OSStatus RunAURenderCallback(
	const AURenderCallbackStruct 	*callbackInfo,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							inNumberFrames,
	AudioBufferList 				*ioData)
{
	if (callbackInfo == nil) return paramErr;
	if (callbackInfo->inputProc == nil) return paramErr;
	
	return callbackInfo->inputProc(callbackInfo->inputProcRefCon,
	ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
}

/*
static OSStatus AudioUnitEnableInput(AudioUnit audioUnit, UInt32 state)
{
	if (audioUnit == nil) return paramErr;
	
	AudioUnitElement inputBus = 1;

	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
	kAudioUnitScope_Input, inputBus, &state, sizeof(state));
}

static OSStatus AudioUnitEnableOutput(AudioUnit audioUnit, UInt32 state)
{
	if (audioUnit == nil) return paramErr;
	
	AudioUnitElement outputBus = 0;

	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
	kAudioUnitScope_Output, outputBus, &state, sizeof(state));
}


static OSStatus AudioUnitSetInputDevice(AudioUnit audioUnit, AudioDeviceID deviceID)
{
	if (audioUnit == nil) return paramErr;


	OSStatus result = noErr;
	
	static const AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultInputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster };
	
	UInt32 size = sizeof(deviceID);
	
	if (deviceID == kAudioDeviceUnknown)
	{
		result = AudioObjectGetPropertyData(kAudioObjectSystemObject,
		&address, 0, nil, &size, &deviceID);
		if (result != noErr) return result;
	}
	
	return AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
	kAudioUnitScope_Global, 0, &deviceID, sizeof(deviceID));
}


static AudioUnit __NewAudioUnitWithDescription(AudioComponentDescription desc)
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


static AudioUnit __NewAudioUnitHALInstance(void)
{
	// User selected output device
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


#endif /* RMSAudioUtilities_h */
