////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixerSource
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSMixerSource.h"
#import "RMSAudioUtilities.h"

@interface RMSMixerSource ()
{
	float mVolume;
	float mBalance;
	
	float mLastVolume;
	float mLastBalance;

	RMSMixerSource *mNextMixerSource;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSMixerSource
////////////////////////////////////////////////////////////////////////////////

float RMSMixerSourceLastVolume(void *source)
{ return ((__bridge RMSMixerSource *)source)->mLastVolume; }

void *RMSMixerSourceNextSource(void *source)
{ return (__bridge void *)((__bridge RMSMixerSource *)source)->mNextMixerSource; }



static void V32f_Add(float *srcPtr, float *dstPtr, UInt32 n)
{
/*
	vDSP_vadd(srcPtr1, 1, srcPtr2, 1, dstPtr, 1, n);
/*/
	while (--n != 0)
	{ dstPtr[n] += srcPtr[n]; }
	dstPtr[0] = srcPtr[0];
/*/
	while (n & (~3))
	{
		dstPtr[0] += srcPtr[0];
		dstPtr[1] += srcPtr[1];
		dstPtr[2] += srcPtr[2];
		dstPtr[3] += srcPtr[3];
		srcPtr += 4;
		dstPtr += 4;
		n -= 4;
	}
	
	if (n & 0x02)
	{
		dstPtr[0] += srcPtr[0];
		dstPtr[1] += srcPtr[1];
		srcPtr += 2;
		dstPtr += 2;
	}

	if (n & 0x01)
	{
		dstPtr[0] += srcPtr[0];
	}
	
//*/
}

////////////////////////////////////////////////////////////////////////////////

static void V32f_AddRamp(float S1, float S2, float *dstPtr, UInt32 n)
{
	S2 -= S1;
	S2 /= n;
	S1 += S2;
	for (; n!=0; n--)
	{
		dstPtr[0] += S1;
		dstPtr++;
		S1 += S2;
	}
}

////////////////////////////////////////////////////////////////////////////////

static void V32f_MultiplyRamp(float S1, float S2, float *dstPtr, UInt32 n)
{
	S2 -= S1;
	S2 /= n;
	S1 += S2;
	for (; n!=0; n--)
	{
		dstPtr[0] *= S1;
		dstPtr++;
		S1 += S2;
	}
}

////////////////////////////////////////////////////////////////////////////////





// Add
static void ADD32f(float *srcPtr1, float *srcPtr2, float *dstPtr, UInt32 n)
{
/*
	vDSP_vadd(srcPtr1, 1, srcPtr2, 1, dstPtr, 1, n);
/*
	while (--n != 0)
	{ dstPtr[n] = srcPtr1[n] + srcPtr2[n]; }
	dstPtr[0] = srcPtr1[0] + srcPtr2[0];
/*/
	while (n & (~3))
	{
		dstPtr[0] = srcPtr1[0] + srcPtr2[0];
		dstPtr[1] = srcPtr1[1] + srcPtr2[1];
		dstPtr[2] = srcPtr1[2] + srcPtr2[2];
		dstPtr[3] = srcPtr1[3] + srcPtr2[3];
		srcPtr1 += 4;
		srcPtr2 += 4;
		dstPtr += 4;
		n -= 4;
	}
	
	if (n & 0x02)
	{
		dstPtr[0] = srcPtr1[0] + srcPtr2[0];
		dstPtr[1] = srcPtr1[1] + srcPtr2[1];
		srcPtr1 += 2;
		srcPtr2 += 2;
		dstPtr += 2;
	}

	if (n & 0x01)
	{
		dstPtr[0] = srcPtr1[0] + srcPtr2[0];
	}
	
//*/
}

////////////////////////////////////////////////////////////////////////////////

// Scalar Multiply Add
static void SMA32f(float *srcPtr, float S, float *dstPtr, UInt32 n)
{
/*
	vDSP_vsma(srcPtr, 1, &S, dstPtr, 1, dstPtr, 1, n);
/*/
	while (--n != 0)
	{ dstPtr[n] += S * srcPtr[n]; }
	dstPtr[0] += S * srcPtr[0];
//*/
}

////////////////////////////////////////////////////////////////////////////////

// Ramped Multiply Add
static void RMA32f(float *srcPtr, float S1, float S2, float *dstPtr, UInt32 n)
{
	S2 -= S1;
	S2 /= n;
	S1 += S2;
/*
	vDSP_vrampmuladd(srcPtr, 1, &S1, &S2, dstPtr, 1, n);
/*/
	for (; n!=0; n--)
	{
		dstPtr[0] += S1 * srcPtr[0];
		srcPtr++;
		dstPtr++;
		S1 += S2;
	}
//*/
}

////////////////////////////////////////////////////////////////////////////////



static void PCM_ApplyVolume
(float V1, float V2, float *dstL, float *dstR, UInt32 n)
{
	V1 = (V2-V1)/n;
	while (n != 0)
	{
		n -= 1;
		
		dstL[n] *= V2;
		dstR[n] *= V2;
		
		V2 -= V1;
	}
}


static void PCM_ApplyPan
(float B1, float B2, float *dstL, float *dstR, UInt32 n)
{
	B1 = (B2-B1)/n;
	while (n != 0)
	{
		n -= 1;
		
		if (B2 > 0.0)
		{ dstL[n] *= 1.0 - B2; }
		else
		if (B2 < 0.0)
		{ dstR[n] *= 1.0 + B2; }
		
		B2 -= B1;
	}
}


static void PCM_ApplyVolumeAndPan
(float V1, float V2, float B1, float B2, float *dstL, float *dstR, UInt32 n)
{
	V1 = (V2-V1)/n;
	B1 = (B2-B1)/n;
	while (n != 0)
	{
		n -= 1;
		
		float L = V2 * dstL[n];
		float R = V2 * dstR[n];
		
		if (B2 > 0.0)
		{ L *= 1.0 - B2; }
		else
		if (B2 < 0.0)
		{ R *= 1.0 + B2; }
		
		dstL[n] = L;
		dstR[n] = R;
		
		V2 -= V1;
		B2 -= B1;
	}
}



static void PCM_VVAdd(
	float V1, float V2,
	float *srcL, float *srcR,
	float *dstL, float *dstR,
	UInt32 n)
{
	V1 = (V2-V1)/n;
	
	while (n != 0)
	{
		n -= 1;
		
		float V = V2;
		dstL[n] += V * srcL[n];
		dstR[n] += V * srcR[n];
		
		V2 -= V1;
	}
}


static void PCM_VVPA(
	float V1, float V2,
	float B1, float B2,
	float *srcL, float *srcR,
	float *dstL, float *dstR,
	float *dstV,
	UInt32 n)
{
	V1 = (V2-V1)/n;
	B1 = (B2-B1)/n;
	while (n != 0)
	{
		n -= 1;
		
		float V = V2 * V2;
		float L = V * srcL[n];
		float R = V * srcR[n];
		
		if (B2 > 0.0)
		{ L *= 1.0 - B2; }
		else
		if (B2 < 0.0)
		{ R *= 1.0 + B2; }
		
		dstL[n] += L;
		dstR[n] += R;
		dstV[n] += V2;
		
		V2 -= V1;
		B2 -= B1;
	}
}

static void PCM_RMA(
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



static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							frameCount,
	AudioBufferList 				*tmpBuffer)
{
	__unsafe_unretained RMSMixerSource *rmsSource = \
	(__bridge __unsafe_unretained RMSMixerSource *)inRefCon;
 
	// Render source into temp buffer
	OSStatus result = RunRMSSource((__bridge void *)rmsSource->mSource,
	ioActionFlags, inTimeStamp, inBusNumber, frameCount, tmpBuffer);

	// Adjust Volume & Pan if necessary
	if (result == noErr)
	{
		/*
			Note: nextBalance & nextVolume need to be local, since
			mBalance and mVolume may change by the main thread while 
			being used here.
		*/
		float nextBalance = rmsSource->mBalance;
		float lastBalance = rmsSource->mLastBalance;

		if ((lastBalance != 0.0)||(nextBalance != 0.0))
		{
			PCM_ApplyPan(lastBalance, nextBalance, \
			tmpBuffer->mBuffers[0].mData, tmpBuffer->mBuffers[1].mData, frameCount);
		}

		rmsSource->mLastBalance = nextBalance;

		float nextVolume = rmsSource->mVolume;
		float lastVolume = rmsSource->mLastVolume;

		if ((lastVolume != 1.0)||(nextVolume != 1.0))
		{
			PCM_ApplyVolume(lastVolume, nextVolume, \
			tmpBuffer->mBuffers[0].mData, tmpBuffer->mBuffers[1].mData, frameCount);
		}

		rmsSource->mLastVolume = nextVolume;
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
		mVolume = 1.0;
		mBalance = 0.0;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithSource:(RMSSource *)source
{ return [[self alloc] initWithSource:source]; }

- (instancetype) initWithSource:(RMSSource *)source
{
	self = [super init];
	if (self != nil)
	{
		mVolume = 1.0;
		mBalance = 0.0;
		[self addSource:source];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (float) volume
{ return mVolume; }

- (void) setVolume:(float)volume
{ mVolume = volume; }

- (float) balance
{ return mBalance; }

- (void) setBalance:(float)balance
{ mBalance = balance; }

////////////////////////////////////////////////////////////////////////////////

- (RMSMixerSource *) nextMixerSource
{ return mNextMixerSource; }

- (void) setNextMixerSource:(RMSMixerSource *)source
{
	if (mNextMixerSource == nil)
	{ mNextMixerSource = source; }
	else
	{ [mNextMixerSource setNextMixerSource:source]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[mSource setSampleRate:sampleRate];
	[super setSampleRate:sampleRate];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
