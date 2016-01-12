////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUtilities
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSAudioUtilities.h"
#import <mach/mach_time.h>

////////////////////////////////////////////////////////////////////////////////

static double g_rmsHostToSeconds = 1.0e-9;
static double g_rmsSecondsToHost = 1.0e+9;

////////////////////////////////////////////////////////////////////////////////

static void RMSHostTimeInit(void)
{
	static bool isInitialized = false;
	if (!isInitialized)
	{
		mach_timebase_info_data_t timeInfo;
		mach_timebase_info(&timeInfo);
		if (timeInfo.numer && timeInfo.denom)
		{
			g_rmsHostToSeconds = 1.0e-9 * timeInfo.numer / timeInfo.denom;
			g_rmsSecondsToHost = 1.0e+9 * timeInfo.denom / timeInfo.numer;
		}
		
		isInitialized = true;
	}
}

////////////////////////////////////////////////////////////////////////////////

double RMSCurrentHostTimeInSeconds(void)
{ return RMSHostTimeToSeconds(mach_absolute_time()); }

double RMSHostTimeToSeconds(double hostTime)
{
	RMSHostTimeInit();
	return hostTime * g_rmsHostToSeconds;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

AudioBufferList *AudioBufferListCreate32f(bool interleaved, UInt32 channelCount, UInt32 frameCount)
{
	AudioBufferList *bufferListPtr = nil;
	
	if (interleaved)
	{
		UInt32 size = sizeof(UInt32) + sizeof(AudioBuffer);
		AudioBufferList *bufferListPtr = malloc(size);
		
		bufferListPtr->mNumberBuffers = 1;
		AudioBufferPrepare32f(&bufferListPtr->mBuffers[0], channelCount, frameCount);
	}
	else
	{
		UInt32 size = sizeof(UInt32) + sizeof(AudioBuffer)*channelCount;
		AudioBufferList *bufferListPtr = malloc(size);
		
		bufferListPtr->mNumberBuffers = channelCount;
		for (UInt32 n=0; n!=channelCount; n++)
		{ AudioBufferPrepare32f(&bufferListPtr->mBuffers[n], 1, frameCount); }
	}
	
	return bufferListPtr;
}

////////////////////////////////////////////////////////////////////////////////

void AudioBufferListRelease(AudioBufferList *bufferListPtr)
{
	if (bufferListPtr != nil)
	{
		for (UInt32 n=0; n!=bufferListPtr->mNumberBuffers; n++)
		{ AudioBufferReleaseMemory(&bufferListPtr->mBuffers[n]); }
		
		free(bufferListPtr);
	}
}

////////////////////////////////////////////////////////////////////////////////

OSStatus AudioBufferPrepare32f(AudioBuffer *bufferPtr, UInt32 channelCount, UInt32 frameCount)
{
	if (bufferPtr == nil) return paramErr;
	if (channelCount == 0) return paramErr;
	if (frameCount == 0) return paramErr;
	
	bufferPtr->mNumberChannels = channelCount;
	bufferPtr->mDataByteSize = channelCount * frameCount * sizeof(Float32);
	bufferPtr->mData = malloc(bufferPtr->mDataByteSize);
	if (bufferPtr->mData == nil) return memFullErr;
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

void AudioBufferReleaseMemory(AudioBuffer *bufferPtr)
{
	if (bufferPtr != nil)
	{
		if (bufferPtr->mData != nil)
		{
			free(bufferPtr->mData);
			bufferPtr->mData = nil;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

void AudioBufferList_ClearBuffers(AudioBufferList *bufferList)
{
	UInt32 n = bufferList->mNumberBuffers;
	while (n != 0)
	{
		n -= 1;
		UInt32 frameCount = bufferList->mBuffers[n].mDataByteSize>>2;
		vDSP_vclr(bufferList->mBuffers[n].mData, 1, frameCount);
	}
}

////////////////////////////////////////////////////////////////////////////////

void AudioBufferList_ClearFrames(AudioBufferList *bufferList, UInt32 frameCount)
{
	UInt32 n = bufferList->mNumberBuffers;
	while (n != 0)
	{
		n -= 1;
		bufferList->mBuffers[n].mDataByteSize = frameCount<<2;
		vDSP_vclr(bufferList->mBuffers[n].mData, 1, frameCount);
	}
}

////////////////////////////////////////////////////////////////////////////////

