////////////////////////////////////////////////////////////////////////////////
/*
	RMSClip
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSClip.h"


@interface RMSClip ()
{
	float *mL;
	float *mR;
	
	UInt32 mIndex;
	UInt32 mCount;
}

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSClip
////////////////////////////////////////////////////////////////////////////////

// forward copy for sliding buffer
static inline void _CopySamples(
	float *srcL, float *dstL,
	float *srcR, float *dstR,
	UInt32 count)
{
	for (UInt32 n=0; n!=count; n++)
	{
		dstL[n] = srcL[n];
		dstR[n] = srcR[n];
	}
}

// convert to power and clip
static inline void _DCT_to_Image(
	float *srcPtr, int srcStep,
	float *dstPtr, int dstStep, UInt32 n)
{
	while(n != 0)
	{
		n -= 1;
		
		dstPtr[0] = srcPtr[0] * srcPtr[0];
		if (dstPtr[0] > 1.0) dstPtr[0] = 1.0;
		
		srcPtr += srcStep;
		dstPtr += dstStep;
	}
}

////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSClip *rmsObject = \
	(__bridge __unsafe_unretained RMSClip *)inRefCon;
	
	float *srcPtrL = rmsObject->mL;
	float *srcPtrR = rmsObject->mR;

	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;
	
	
	UInt32 srcIndex = rmsObject->mIndex;

	for (UInt32 n=0; n!=frameCount; n++)
	{
		dstPtrL[n] = srcPtrL[srcIndex];
		dstPtrR[n] = srcPtrR[srcIndex];
		srcIndex += 1;
		
		if (srcIndex == rmsObject->mCount)
		{ srcIndex = 0; }
	}
	
	rmsObject->mIndex = srcIndex;
	
	return noErr;
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
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) sineWaveWithLength:(UInt64)N
{
	RMSClip *sineWave = [[self alloc] initWithLength:N];
	
	for (UInt32 n=0; n!=N; n++)
	{
		double x = (1.0*n+0.5)/N;
		double y = sin(x*2.0*M_PI);
		sineWave->mL[n] = y;
		sineWave->mR[n] = y;
	}
	
	return sineWave;
}

////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithLength:(UInt64)size
{
	self = [super init];
	if (self != nil)
	{
		mCount = size;
		mL = calloc(size, sizeof(float));
		mR = calloc(size, sizeof(float));
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	if (mL != nil)
	{
		free(mL);
		mL = nil;
	}
	
	if (mR != nil)
	{
		free(mR);
		mR = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (UInt32) sampleCount
{ return mCount; }

- (float *) getPtrL
{ return mL; }

- (float *) getPtrR
{ return mR; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



