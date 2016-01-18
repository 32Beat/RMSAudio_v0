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
	double mLastM;
	double mLastQ;
	
	double mL[16];
	double mR[16];
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSLowPassFilter
////////////////////////////////////////////////////////////////////////////////

static inline float LPProcessSample(float M, float Q, float *A, float S)
{
	A[0] = A[1];
	A[1] = A[2];
	A[2] = S;
	float An = 0.25 * (A[0] + A[1] + A[1] + A[2]);
	
	return An + M * (A[1] - An) ;
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
		L = LPProcessSample(M, Q, &AL[0], L);
		L = LPProcessSample(M, Q, &AL[4], L);
		L = LPProcessSample(M, Q, &AL[8], L);
		L = LPProcessSample(M, Q, &AL[12], L);
		*ptrL++ = L;
		
		float R = ptrR[0];
		R = LPProcessSample(M, Q, &AR[0], R);
		R = LPProcessSample(M, Q, &AR[4], R);
		R = LPProcessSample(M, Q, &AR[8], R);
		R = LPProcessSample(M, Q, &AR[12], R);
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
	
	double S = rmsObject->mSampleRate;

	//
	if (rmsObject->mLastM == 0.0)
	{ rmsObject->mLastM = rmsObject->mFrequency * 2.0 / S; }


	double M = rmsObject->mLastM;
	double Mnext = rmsObject->mFrequency * 2.0 / S;
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

- (float) resonance
{ return mResonance; }

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
	
	[self setFrequency:F];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFrequency:(float)f
{
	if (f < 20.0) f = 20.0;
	
	mFrequency = f;
}

////////////////////////////////////////////////////////////////////////////////

- (float) frequency
{ return mFrequency; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
