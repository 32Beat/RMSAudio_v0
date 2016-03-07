////////////////////////////////////////////////////////////////////////////////
/*
	RMSVolume
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSVolume.h"
#import <Accelerate/Accelerate.h>


@interface RMSVolume ()
{
	float mGain;
	
	float mLastVolume;
	float mNextVolume;

	float mLastBalance;
	float mNextBalance;
}

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSVolume
////////////////////////////////////////////////////////////////////////////////

float RMSVolumeGetLastVolume(void *source)
{ return ((__bridge RMSVolume *)source)->mLastVolume; }


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

////////////////////////////////////////////////////////////////////////////////

static void PCM_ApplyBalance
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

////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSVolume *rmsObject = \
	(__bridge __unsafe_unretained RMSVolume *)inRefCon;

	/*
		Note: nextBalance & nextVolume need to be local, since
		they may change by the main thread while being used here.
	*/
	
	float lastVolume = rmsObject->mLastVolume;
	float nextVolume = rmsObject->mNextVolume * pow(10, 0.05*rmsObject->mGain);
	if ((lastVolume != 1.0)||(nextVolume != 1.0))
	{
		PCM_ApplyVolume(lastVolume, nextVolume,
			bufferList->mBuffers[0].mData,
			bufferList->mBuffers[1].mData,
			frameCount);
		rmsObject->mLastVolume = nextVolume;
	}

	float lastBalance = rmsObject->mLastBalance;
	float nextBalance = rmsObject->mNextBalance;
	if ((lastBalance != 0.0)||(nextBalance != 0.0))
	{
		PCM_ApplyBalance(lastBalance, nextBalance,
			bufferList->mBuffers[0].mData,
			bufferList->mBuffers[1].mData,
			frameCount);
		rmsObject->mLastBalance = nextBalance;
	}
	
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
		mNextVolume = 1.0;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (float) gain
{ return mGain; }

- (void) setGain:(float)gain
{ mGain = gain; }

////////////////////////////////////////////////////////////////////////////////

- (float) volume
{ return mNextVolume; }

- (void) setVolume:(float)volume
{ mNextVolume = volume; }

////////////////////////////////////////////////////////////////////////////////

- (float) balance
{ return mNextBalance; }

- (void) setBalance:(float)balance
{ mNextBalance = balance; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
