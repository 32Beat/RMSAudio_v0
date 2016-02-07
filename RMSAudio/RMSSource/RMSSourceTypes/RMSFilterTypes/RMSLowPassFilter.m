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

static inline double _ComputeMultiplier(double Fc, double Fs)
{ return 1.0 - exp(-2.0*M_PI*Fc/Fs); }

static inline float ProcessSampleLP(float M, float Q, float *A, float S)
{
#pragma unused(Q)

	return A[0] += M * (S - A[0]) ;
}

static inline float ProcessSampleAP(float M, float Q, float *A, float S)
{
#pragma unused(Q)

	float R = A[0];
	
	S += M * R;
	R -= M * S;
	
	A[0] = S;
	
	return R;
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
		L = ProcessSampleLP(M, Q, AL, L);
		*ptrL++ = L;
		
		float R = ptrR[0];
		R = ProcessSampleLP(M, Q, AR, R);
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
	
	float S = rmsObject->mSampleRate;

	// Initialize if necessary
	if (rmsObject->mLastM == 0.0)
	{ rmsObject->mLastM = _ComputeMultiplier(rmsObject->mFrequency, S); }


	double M = rmsObject->mLastM;
	double Mnext = _ComputeMultiplier(rmsObject->mFrequency, S);
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
