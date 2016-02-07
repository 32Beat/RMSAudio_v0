////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixer
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSMixer.h"
#import "RMSMixerSource.h"

#import "RMSVolume.h"


@interface RMSMixer ()
{
	RMSVolume *mVolumeFilter;
	RMSMixerSource *mFirstSource;

	float mNextVolume;
	float mLastVolume;
	
	UInt32 mSourceCount;
	UInt32 mMaxFrameCount;
	RMSStereoBufferList32f mCacheBuffer;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSMixer
////////////////////////////////////////////////////////////////////////////////

static inline void _AddSamples(
	float *srcL, float *dstL,
	float *srcR, float *dstR,
	UInt32 n)
{
//	vDSP_vadd(srcL, 1, dstL, 1, dstL, 1, n);
//	vDSP_vadd(srcR, 1, dstR, 1, dstR, 1, n);

	// By the time vDSP has figured out which optimization to use (twice)
	// the following has probably finished already
	while(n != 0)
	{
		n -= 1;
		dstL[n] += srcL[n];
		dstR[n] += srcR[n];
	}
}

////////////////////////////////////////////////////////////////////////////////

static inline void AudioBufferList_AddSamples(
	AudioBufferList *srcBuffer,
	AudioBufferList *dstBuffer,
	UInt32 n)
{
	_AddSamples(
	srcBuffer->mBuffers[0].mData,
	dstBuffer->mBuffers[0].mData,
	srcBuffer->mBuffers[1].mData,
	dstBuffer->mBuffers[1].mData, n);
}

////////////////////////////////////////////////////////////////////////////////




static void _RMA(
	float V1, float V2,
	float *srcL, float *srcR,
	float *dstL, float *dstR,
	UInt32 n)
{
	V1 = (V2-V1)/n;
	while (n != 0)
	{
		n -= 1;
		
		dstL[n] += V2 * srcL[n];
		dstR[n] += V2 * srcR[n];
		
		V2 -= V1;
	}
}

static void PCM_RMA(
	float V1, float V2,
	AudioBufferList *srcBuffer,
	AudioBufferList *dstBuffer,
	UInt32 n)
{
	_RMA(V1, V2,
	srcBuffer->mBuffers[0].mData,
	srcBuffer->mBuffers[1].mData,
	dstBuffer->mBuffers[0].mData,
	dstBuffer->mBuffers[1].mData, n);
}

static void DivideByTotalVolume(AudioBufferList *bufferList, float V1, float V2, UInt32 n)
{
	V1 = (V2-V1)/n;
	
	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;
	
	while (n != 0)
	{
		n -= 1;

		float V = V2;
		float L = dstPtrL[n];
		float R = dstPtrR[n];
		if (L < V)
		{ dstPtrL[n] = L / V; }
		if (R < V)
		{ dstPtrR[n] = R / V; }
		
		V2 -= V1;
	}
}

////////////////////////////////////////////////////////////////////////////////
static OSStatus weightedMix(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*mixBuffer)
{
	__unsafe_unretained RMSMixer *rmsMixer = \
	(__bridge __unsafe_unretained RMSMixer *)inRefCon;

	// TODO: implement proper loop
	if (frameCount > rmsMixer->mMaxFrameCount)
	{
		NSLog(@"frameCount = %d !", frameCount);
		frameCount = rmsMixer->mMaxFrameCount;
	}

	OSStatus result = noErr;


	// Clear mixBuffer
	AudioBufferList_ClearBuffers(mixBuffer);
	
	// Render source into tmpBuffer, and add to mixBuffer
	AudioBufferList *tmpBuffer = (AudioBufferList *)&rmsMixer->mCacheBuffer;


	// Ramp-parameters for total volume
	rmsMixer->mLastVolume = rmsMixer->mNextVolume;
	rmsMixer->mNextVolume = 0.0;
	
	void *source = (__bridge void *)rmsMixer->mFirstSource;
	
	// Accumulate Chained RMSMixerSources
	while (source != nil)
	{
		// Clear cachebuffer, also reset mDataByteSize
		AudioBufferList_ClearFrames(tmpBuffer, frameCount);

		float lastVolume = RMSMixerSourceGetLastVolume(source);
		
		result = RunRMSSource(source, \
		actionFlags, timeStamp, busNumber, frameCount, tmpBuffer);
		
		float nextVolume = RMSMixerSourceGetLastVolume(source);

		// Add to mixer result with volume weight
		PCM_RMA(lastVolume, nextVolume, tmpBuffer, mixBuffer, frameCount);
		rmsMixer->mNextVolume += nextVolume;
		
		source = RMSMixerSourceGetNextSource(source);
	}
	
	// Adjust overall volume
	DivideByTotalVolume(mixBuffer, rmsMixer->mLastVolume, rmsMixer->mNextVolume, frameCount);
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////
/*
	Note: AudioUnits may adjust the AudioBufferList, 
	particularly the FilePlayer will adjust the mDataByteSize field. 
	This will happen on the mCacheBuffer possibly making it invalid 
	for subsequent calls. The AudioBufferList_ClearFrames will reset 
	the mDataByteSize field to the corresponding length.
*/
static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*mixBuffer)
{
	__unsafe_unretained RMSMixer *rmsMixer = \
	(__bridge __unsafe_unretained RMSMixer *)inRefCon;

	// TODO: implement proper loop
	if (frameCount > rmsMixer->mMaxFrameCount)
	{
		NSLog(@"frameCount = %d !", frameCount);
		frameCount = rmsMixer->mMaxFrameCount;
	}

	OSStatus result = noErr;

	
	// Clear incoming audioBuffers
	AudioBufferList_ClearBuffers(mixBuffer);
	
	// Get convenience reference to cacheBuffer
	AudioBufferList *tmpBuffer = (AudioBufferList *)&rmsMixer->mCacheBuffer;
	
	
	// Render each source into cacheBuffer, and add to mixBuffer
	void *source = (__bridge void *)rmsMixer->mFirstSource;
	
	// Accumulate Chained RMSMixerSources
	while (source != nil)
	{
		// Clear cachebuffer, also reset mDataByteSize
		AudioBufferList_ClearFrames(tmpBuffer, frameCount);
		
		// Render source into tmp buffer
		result = RunRMSSource(source, \
		actionFlags, timeStamp, busNumber, frameCount, tmpBuffer);
		
		// Add tmp buffer to audiobuffer
		AudioBufferList_AddSamples(tmpBuffer, mixBuffer, frameCount);
		
		// Fetch next source
		source = RMSMixerSourceGetNextSource(source);
	}
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{
	self = [super init];
	if (self != nil)
	{
		mMaxFrameCount = 2048;
		mCacheBuffer.bufferCount = 2;
		AudioBufferPrepare32f(&mCacheBuffer.buffer[0], 1, mMaxFrameCount);
		AudioBufferPrepare32f(&mCacheBuffer.buffer[1], 1, mMaxFrameCount);
		
		mVolumeFilter = [RMSVolume new];
		[self addFilter:mVolumeFilter];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setVolume:(float)volume
{
	[mVolumeFilter setVolume:volume];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setBalance:(float)balance
{
	[mVolumeFilter setBalance:balance];
}

////////////////////////////////////////////////////////////////////////////////

- (id) addSource:(RMSSource *)source
{
	if (source == nil) return nil;
	
	RMSMixerSource *mixerSource = [RMSMixerSource instanceWithSource:source];
	[self addMixerSource:mixerSource];
	return mixerSource;
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeSource:(RMSSource *)source
{
	RMSMixerSource *mixerSource = [self findMixerSourceWithSource:source];
	if (mixerSource!=nil)
	{ [self removeMixerSource:mixerSource]; }
	
}

////////////////////////////////////////////////////////////////////////////////

- (id) findMixerSourceWithSource:(RMSSource *)source
{
	RMSMixerSource *mixerSource = mFirstSource;
	while(mixerSource != nil)
	{
		if (mixerSource.source == source)
		{
			return mixerSource;
		}
		
		mixerSource = [mixerSource nextMixerSource];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) addMixerSource:(RMSMixerSource *)mixerSource
{
	[mixerSource setSampleRate:[self sampleRate]];
	
	if (mFirstSource == nil)
	{ mFirstSource = mixerSource; }
	else
	{ [mFirstSource addNextMixerSource:mixerSource]; }

	mSourceCount += 1;
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeMixerSource:(RMSMixerSource *)mixerSource
{
	if (mFirstSource == mixerSource)
	{
		id oldObject = mFirstSource;
		mFirstSource = [mFirstSource nextMixerSource];
		[self trashObject:oldObject];
	}
	else
	[mFirstSource removeNextMixerSource:mixerSource];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	
	RMSMixerSource *source = mFirstSource;
	while(source != nil)
	{
		[source setSampleRate:sampleRate];
		source = [source nextMixerSource];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
