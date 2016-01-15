////////////////////////////////////////////////////////////////////////////////
/*
	RMSLowPassFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSLowPassFilter.h"


static inline double Clip(double x)
{ return -1.0 < x ? x < +1.0 ? x : +1.0 : -1.0; }

@interface RMSLowPassFilter ()
{
	double mCutOff;
	double mResonance;

	double mLastCutOff;
	double mLastResonance;
	
	double mL0;
	double mL1;
	double mL2;
	double mL3;
	double mLL3;

	double mR0;
	double mR1;
	double mR2;
	double mR3;
	double mRR3;
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
	
	double L0 = rmsObject->mL0;
	double L1 = rmsObject->mL1;
	double L2 = rmsObject->mL2;
	double L3 = rmsObject->mL3;
	double LL3 = rmsObject->mLL3;

	double R0 = rmsObject->mR0;
	double R1 = rmsObject->mR1;
	double R2 = rmsObject->mR2;
	double R3 = rmsObject->mR3;
	double RR3 = rmsObject->mRR3;

	double S = rmsObject->mSampleRate;

	//
	if (rmsObject->mLastCutOff == 0.0)
	{ rmsObject->mLastCutOff = rmsObject->mCutOff * 2.0 / S; }


	double F = rmsObject->mLastCutOff;
	double Fnext = rmsObject->mCutOff * 2.0 / S;
	double Fstep = (Fnext - F) / frameCount;
	
	double R = rmsObject->mLastResonance;
	double Rnext = rmsObject->mResonance * 4.0;
	double Rstep = (Rnext - R) / frameCount;


	for (UInt32 n=0; n!=frameCount; n++)
	{
		F += Fstep;
		R += Rstep;
//
#define Compute(Q, M, S0, A0, A1, A2, A3, AA3) \
{ \
	AA3 += 0.5*(A3-AA3); \
	S0 -= Q * AA3; \
	S0 = Clip(S0); \
	A0 += M * (S0 - A0); \
	A1 += M * (A0 - A1); \
	A2 += M * (A1 - A2); \
	A3 += M * (A2 - A3); \
}
		double S0 = dstPtrL[n];

		Compute(R, F, S0, L0, L1, L2, L3, LL3);

		dstPtrL[n] = L3;
		
		
		S0 = dstPtrR[n];

		Compute(R, F, S0, R0, R1, R2, R3, RR3);

		dstPtrR[n] = R3;
	}

	rmsObject->mLastCutOff = F;
	rmsObject->mLastResonance = R;

	rmsObject->mL0 = L0;
	rmsObject->mL1 = L1;
	rmsObject->mL2 = L2;
	rmsObject->mL3 = L3;
	rmsObject->mLL3 = LL3;

	rmsObject->mR0 = R0;
	rmsObject->mR1 = R1;
	rmsObject->mR2 = R2;
	rmsObject->mR3 = R3;
	rmsObject->mRR3 = RR3;

	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (void) setResonance:(float)value
{
	if (value < 0.0) value = 0.0;
	if (value > 1.0) value = 1.0;
	mResonance = value;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCutOff:(float)value
{
	float minF = 20.0;
	float maxF = 20000.0;
	float F = minF + value * value * (maxF - minF);
	
	[self setCutOffFrequency:F];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCutOffFrequency:(float)f
{
	if (f < 20.0) f = 20.0;
	
	mCutOff = f;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
