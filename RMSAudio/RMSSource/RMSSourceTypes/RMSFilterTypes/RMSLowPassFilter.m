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
	double mLastM;
	double mLastQ;
	
	float mL[16];
	float mR[16];
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSLowPassFilter
////////////////////////////////////////////////////////////////////////////////

static inline float LPProcessSample(float F, float *A, float S)
{
	UInt32 n = 0;
	A[0] = S;

	float f = 20000;
	float m = 0.5;
	while (f > F)
	{
		n += 1;

		S = (A[n] += m * (S - A[n]));

		f *= 0.5;
		m *= 0.5;
	}
	
	if (f < F)
	{
		S += (F - f) * (A[n-1] - S) / f;
	}
	
	while (++n & 15)
	{ A[n] = 0; }
	
	return S ;
}

////////////////////////////////////////////////////////////////////////////////

static inline void LPProcessSamples(
	double M, double Mstep,
	double Q, double Qstep,
	float *AL, float *ptrL,
	float *AR, float *ptrR,
	UInt32 frameCount)
{
	do
	{
		float L = ptrL[0];
		L = LPProcessSample(M, AL, L);
		*ptrL++ = L;
		
		float R = ptrR[0];
		R = LPProcessSample(M, AR, R);
		*ptrR++ = R;

		M += Mstep;
		Q += Qstep;
	}
	while(--frameCount != 0);
}

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
	
	//
	if (rmsObject->mLastM == 0.0)
	{ rmsObject->mLastM = rmsObject->mFrequency; }


	double M = rmsObject->mLastM;
	double Mnext = rmsObject->mFrequency;
	double Mstep = (Mnext - M) / frameCount;
	
	double R = rmsObject->mLastQ;
	double Rnext = rmsObject->mResonance * 4.0;
	double Rstep = (Rnext - R) / frameCount;

	rmsObject->mLastM = Mnext;
	rmsObject->mLastQ = Rnext;

	// Filter samples 
	LPProcessSamples(
			M, Mstep, R, Rstep,
			rmsObject->mL, dstPtrL,
			rmsObject->mR, dstPtrR, frameCount);
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (void) setCutOff:(float)value
{
	float minF = 20.0;
	float maxF = 20000.0;
	float F = minF + value * value * (maxF - minF);
	
	[self setFrequency:F];
}

////////////////////////////////////////////////////////////////////////////////

- (float) frequency
{ return mFrequency; }

- (void) setFrequency:(float)f
{
	if (f < 20.0) f = 20.0;
	
	mFrequency = f;
}

////////////////////////////////////////////////////////////////////////////////

- (float) resonance
{ return mResonance; }

- (void) setResonance:(float)value
{
	if (value < 0.0) value = 0.0;
	if (value > 1.0) value = 1.0;
	mResonance = value;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
