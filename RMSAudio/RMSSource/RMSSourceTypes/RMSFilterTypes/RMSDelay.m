////////////////////////////////////////////////////////////////////////////////
/*
	RMSDelay
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSDelay.h"
#import "rmsdelay_t.h"
#import "rmsoscillator_t.h"


@interface RMSDelay ()
{
	float mTime;
	float mFeedBack;
	float mMix;
	
	float mLastD;
	float mLastF;
	float mLastM;
	
	rmsoscillator_t mLFO;
	rmsdelay_t mDelayL;
	rmsdelay_t mDelayR;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSDelay
////////////////////////////////////////////////////////////////////////////////

static inline float rmsWeight(float x)
{ return 1.0-x*x; }

static inline float rmsBalance(float S1, float S2, float B)
{ return S1 * rmsWeight(B) + S2 * rmsWeight(1-B); }

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

	// delay offset
	float D = rmsObject->mLastD;
	float Dnext = rmsObject->mTime * rmsObject->mSampleRate;
	float Dstep = (Dnext - D) / frameCount;

	// delay feedback
	float F = rmsObject->mLastF;
	float Fnext = rmsObject->mFeedBack;
	float Fstep = (Fnext - F) / frameCount;

	// dry-wet mix
	float M = rmsObject->mLastM;
	float Mnext = rmsObject->mMix;
	float Mstep = (Mnext - M) / frameCount;
	
	rmsObject->mLastD = Dnext;
	rmsObject->mLastF = Fnext;
	rmsObject->mLastM = Mnext;


	// Fetch buffer pointers
	float *ptrL = bufferList->mBuffers[0].mData;
	float *ptrR = bufferList->mBuffers[1].mData;

	do
	{
		float Y = .1*RMSOscillatorFetchSample(&rmsObject->mLFO);
		
		// Compute dry-wet mix
		float L0 = ptrL[0];
		float L1 = RMSDelayProcessSample(&rmsObject->mDelayL, D+D*Y, F, L0);
		//*ptrL++ = L0 + M * (L1 - L0);
		*ptrL++ = rmsBalance(L0, L1, M);
		
		// Compute dry-wet mix
		float R0 = ptrR[0];
		float R1 = RMSDelayProcessSample(&rmsObject->mDelayR, D-D*Y, F, R0);
		//*ptrR++ = R0 + M * (R1 - R0);
		*ptrR++ = rmsBalance(R0, R1, M);
		
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
		mLFO = RMSOscillatorBeginTriangleWave(.1, 44100.0);
		mDelayL = RMSDelayBegin();
		mDelayR = RMSDelayBegin();
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSDelayEnd(&mDelayL);
	RMSDelayEnd(&mDelayR);
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDelay:(float)delay
{
	NSTimeInterval time = pow(10, -4 + 5 * delay);
	[self setDelayTime:time];
}

////////////////////////////////////////////////////////////////////////////////

- (NSTimeInterval) delayTime
{ return mTime; }

- (void) setDelayTime:(NSTimeInterval)time
{ mTime = time; }

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










