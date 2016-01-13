////////////////////////////////////////////////////////////////////////////////
/*
	RMSLowPassFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSLowPassFilter.h"


@interface RMSLowPassFilter ()
{
	float mCutOff;
	float mResonance;

	volatile float mLR;
	volatile float mLM;
	float mL0;
	float mL1;
	float mL2;

	volatile float mRR;
	volatile float mRM;
	float mR0;
	float mR1;
	float mR2;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSLowPassFilter
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*refCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSLowPassFilter *rmsObject = \
	(__bridge __unsafe_unretained RMSLowPassFilter *)refCon;

	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;
	
	float L0 = rmsObject->mL0;
	float L1 = rmsObject->mL1;
	float L2 = rmsObject->mL2;

	float R0 = rmsObject->mR0;
	float R1 = rmsObject->mR1;
	float R2 = rmsObject->mR2;

	for (UInt32 n=0; n!=frameCount; n++)
	{
/*
		float LM = rmsObject->mLM;
		L0 += LM * (dstPtrL[n] - L0);
		L1 += LM * (L0 - L1);
		//L2 += LM * (L1 - L2);
		dstPtrL[n] = L1;
		
		float RM = rmsObject->mRM;
		R0 += RM * (dstPtrR[n] - R0);
		R1 += RM * (R0 - R1);
		//R2 += RM * (R1 - R2);
		dstPtrR[n] = R1;
*/

#define Compute(R, M, S0, A0, A1, A2) { \
	S0 += R * (A0 - A1); \
	A0 += M * (S0 - A0); \
	A1 += M * (A0 - A1); \
	A2 += M * (A1 - A2); }

		float LR = rmsObject->mLR;
		float LM = rmsObject->mLM;

		float S0 = dstPtrL[n];

		Compute(LR, LM, S0, L0, L1, L2);

		dstPtrL[n] = L2;
		
		float RR = rmsObject->mRR;
		float RM = rmsObject->mRM;
		
		S0 = dstPtrR[n];

		Compute(RR, RM, S0, R0, R1, R2);

		dstPtrR[n] = R2;
	}

	rmsObject->mL0 = L0;
	rmsObject->mL1 = L1;
	rmsObject->mL2 = L2;

	rmsObject->mR0 = R0;
	rmsObject->mR1 = R1;
	rmsObject->mR2 = R2;
	
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
		mLM = 1.0;
		mRM = 1.0;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setResonance:(float)value
{
	if (value < 0.0) value = 0.0;
	if (value > 1.0) value = 1.0;
	mResonance = value;
	[self updateMultipliers];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCutOff:(float)f
{
	float minF = 20.0;
	float maxF = 20000.0;
	
	[self setCutOffFrequency:minF + f * f * (maxF - minF)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCutOffFrequency:(float)f
{
	if (f < 20.0) f = 20.0;
	
	mCutOff = f;
	[self updateMultipliers];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	[self updateMultipliers];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateMultipliers
{
	double maxF = 0.5 * mSampleRate;
	double m = mCutOff < maxF ? mCutOff / maxF : 1.0;
	mLM = m;
	mRM = m;
	
	mLR = mResonance + mResonance / (1.01 - m);
	mRR = mResonance + mResonance / (1.01 - m);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
