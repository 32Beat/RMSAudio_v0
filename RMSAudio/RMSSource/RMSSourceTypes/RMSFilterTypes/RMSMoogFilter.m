////////////////////////////////////////////////////////////////////////////////
/*
	RMSMoogFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSMoogFilter.h"


// static inline float Clip(float x) \
{ return -1.0 < x ? x < +1.0 ? x : +1.0 : -1.0; }

static inline float SoftClip(float x)
{ return -1.5 < x ? x < +1.5 ? x -(4.0/27.0)*x*x*x : +1.5 : -1.5; }


typedef float RMSNativeFloat;

@interface RMSMoogFilter ()
{
	RMSNativeFloat mCutOff;
	RMSNativeFloat mResonance;

	RMSNativeFloat mLastCutOff;
	RMSNativeFloat mLastResonance;
	
	RMSNativeFloat mL[8];
	RMSNativeFloat mR[8];
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSMoogFilter
////////////////////////////////////////////////////////////////////////////////

static void MoogProcessSamples(
	RMSNativeFloat Q, RMSNativeFloat Qstep,
	RMSNativeFloat M, RMSNativeFloat Mstep, RMSNativeFloat *A,
	float *samplePtr, UInt32 frameCount)
{
	do
	{
		double S = samplePtr[0];
		
		// Adjust feedback delay for hf stability
		A[4] += 0.5 * (A[3]-A[4]);
		
		// Add feedback with inverted phase
		// (basically this subtracts delayed low frequency content)
		S -= Q * A[4];
		S = SoftClip(S);
		
		// Filter sample value
		A[0] += M * (S - A[0]);
		A[1] += M * (A[0] - A[1]);
		A[2] += M * (A[1] - A[2]);
		A[3] += M * (A[2] - A[3]);
		
		*samplePtr++ = A[3];

		Q += Qstep;
		M += Mstep;
	}
	while(--frameCount != 0);
}

////////////////////////////////////////////////////////////////////////////////

static inline void MoogProcessSamples2(
	RMSNativeFloat Q, RMSNativeFloat Qstep,
	RMSNativeFloat M, RMSNativeFloat Mstep,
	RMSNativeFloat *AL, float *ptrL,
	RMSNativeFloat *AR, float *ptrR,
	UInt32 frameCount)
{

	#define Update(Q, M, S, A) \
	{ \
		A[4] += 0.5*(A[3]-A[4]); \
		S -= Q * A[4]; \
		S = SoftClip(S); \
		A[0] += M * (S   -A[0]); \
		A[1] += M * (A[0]-A[1]); \
		A[2] += M * (A[1]-A[2]); \
		A[3] += M * (A[2]-A[3]); \
	}

	do
	{
		RMSNativeFloat L = ptrL[0];
		
		Update(Q, M, L, AL);
		
		*ptrL++ = AL[3];

		RMSNativeFloat R = ptrR[0];

		Update(Q, M, R, AR);
		
		*ptrR++ = AR[3];

		Q += Qstep;
		M += Mstep;
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
	__unsafe_unretained RMSMoogFilter *rmsObject = \
	(__bridge __unsafe_unretained RMSMoogFilter *)refCon;

	// Prepare internal parameters
	double S = rmsObject->mSampleRate;

	// initialize if necessary
	if (rmsObject->mLastCutOff == 0.0)
	{ rmsObject->mLastCutOff = rmsObject->mCutOff * 2.0 / S; }

	double F = rmsObject->mLastCutOff;
	double Fnext = rmsObject->mCutOff * 2.0 / S;
	double Fstep = (Fnext - F) / frameCount;
	
	double R = rmsObject->mLastResonance;
	double Rnext = rmsObject->mResonance * 4.0;
	double Rstep = (Rnext - R) / frameCount;
	
	rmsObject->mLastCutOff = Fnext;
	rmsObject->mLastResonance = Rnext;

	// Fetch buffer pointers
	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;

	// Filter samples 
	MoogProcessSamples2(
		R, Rstep, F, Fstep,
		rmsObject->mL, dstPtrL,
		rmsObject->mR, dstPtrR, frameCount);

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
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////