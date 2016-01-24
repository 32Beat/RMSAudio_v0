////////////////////////////////////////////////////////////////////////////////
/*
	RMSDelay
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSDelay.h"
#import "rmsdelay_t.h"


@interface RMSDelay ()
{
	float mTime;
	float mFeedBack;
	float mMix;
	
	float mLastD;
	float mLastF;
	float mLastM;
	
	rmsdelay_t mDelayL;
	rmsdelay_t mDelayR;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSDelay
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSDelay *rmsObject = \
	(__bridge __unsafe_unretained RMSDelay *)inRefCon;


	double D = rmsObject->mLastD;
	double Dnext = rmsObject->mTime * rmsObject->mSampleRate;
	double Dstep = (Dnext - D) / frameCount;

	double F = rmsObject->mLastF;
	double Fnext = rmsObject->mFeedBack;
	double Fstep = (Fnext - F) / frameCount;

	double M = rmsObject->mLastM;
	double Mnext = rmsObject->mMix;
	double Mstep = (Mnext - M) / frameCount;
	
	rmsObject->mLastD = Dnext;
	rmsObject->mLastF = Fnext;
	rmsObject->mLastM = Mnext;


	// Fetch buffer pointers
	float *ptrL = bufferList->mBuffers[0].mData;
	float *ptrR = bufferList->mBuffers[1].mData;

	do
	{
		double L0 = ptrL[0];
		double L1 = RMSDelayProcessSample(&rmsObject->mDelayL, D, F, L0);
		*ptrL++ = L0 + M * (L1 - L0);
		
		double R0 = ptrR[0];
		double R1 = RMSDelayProcessSample(&rmsObject->mDelayR, D, F, R0);
		*ptrR++ = R0 + M * (R1 - R0);
		
		D += Dstep;
		F += Fstep;
		M += Mstep;
	}
	while(--frameCount != 0);
	
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
		mDelayL = RMSDelayNew();
		mDelayR = RMSDelayNew();
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSDelayReleaseMemory(&mDelayL);
	RMSDelayReleaseMemory(&mDelayR);
}

////////////////////////////////////////////////////////////////////////////////

- (float) delayTime
{ return mTime; }

- (void) setDelayTime:(float)time
{ mTime = pow(10, -4 + 5 * time); }

////////////////////////////////////////////////////////////////////////////////

- (float) feedBack
{ return mFeedBack; }

- (void) setFeedBack:(float)value
{ mFeedBack = value; }

////////////////////////////////////////////////////////////////////////////////

- (float) mix
{ return mMix; }

- (void) setMix:(float)value
{ mMix = value; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////










