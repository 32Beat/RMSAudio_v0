////////////////////////////////////////////////////////////////////////////////
/*
	RMSMoogFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.

	From:
	NON-LINEAR DIGITAL IMPLEMENTATION OF THE MOOG LADDER FILTER
	Antti Huovilainen
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSMoogFilter.h"


@interface RMSMoogFilter ()
{
	double mLastM;
	double mLastQ;
	
	double mL[8];
	double mR[8];
}
@end


////////////////////////////////////////////////////////////////////////////////
// Helper functions

static inline double RMSMoogFilterComputeMultiplier(double Fc, double Fs)
{ return 1.0 - exp(-2.0*M_PI*Fc/Fs); }

static inline double RMSMoogFilterComputeResonance(double R)
{ return 4.0 * R; }


////////////////////////////////////////////////////////////////////////////////
@implementation RMSMoogFilter
////////////////////////////////////////////////////////////////////////////////

static inline double MoogProcessSample(double M, double Q, double *A, double S)
{
	// Phase shift compensation
	A[4] += 0.5*(A[3]-A[4]);
	
	// Feedback
	S -= Q * A[4];
	S = HardClip(S);
	
	// Ladder
	A[0] += M * (S   -A[0]);
	A[1] += M * (A[0]-A[1]);
	A[2] += M * (A[1]-A[2]);
	A[3] += M * (A[2]-A[3]);
	
	return A[3];
}

////////////////////////////////////////////////////////////////////////////////

static inline void MoogProcessSamples1(
	double M, double Mstep,
	double Q, double Qstep,
	double *AL, float *ptrL,
	double *AR, float *ptrR,
	UInt32 frameCount)
{
	do
	{
		double L = MoogProcessSample(M, Q, AL, ptrL[0]);
		*ptrL++ = L;
		double R = MoogProcessSample(M, Q, AR, ptrR[0]);
		*ptrR++ = R;

		M += Mstep;
		Q += Qstep;
	}
	while(--frameCount != 0);
}

////////////////////////////////////////////////////////////////////////////////

static inline void MoogProcessSamples2(
	double M, double Mstep,
	double Q, double Qstep,
	double *AL, float *ptrL,
	double *AR, float *ptrR,
	UInt32 frameCount)
{
	// Fetch source samples from previous run (initially 0.0)
	double SL = AL[7];
	double SR = AR[7];

	do
	{
		// Interpolate between previous samples and new samples
		SL += ptrL[0];
		SL *= 0.5;
		double L = MoogProcessSample(M, Q, AL, SL);

		SR += ptrR[0];
		SR *= 0.5;
		double R = MoogProcessSample(M, Q, AR, SR);
		
		// Process new samples and accumulate
		SL = ptrL[0];
		L += MoogProcessSample(M, Q, AL, SL);
		SR = ptrR[0];
		R += MoogProcessSample(M, Q, AR, SR);
		
		// Store average result
		*ptrL++ = 0.5*L;
		*ptrR++ = 0.5*R;

		// Update once per loop, half-step is overly precise
		M += Mstep;
		Q += Qstep;

	}
	while(--frameCount != 0);
	
	// Save last samples for next run
	AL[7] = SL;
	AR[7] = SR;
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
	if (rmsObject->mLastM == 0.0)
	{ rmsObject->mLastM = RMSMoogFilterComputeMultiplier(rmsObject->mFrequency, S); }

	double M = rmsObject->mLastM;
	double Mnext = RMSMoogFilterComputeMultiplier(rmsObject->mFrequency, S);
	double Mstep = (Mnext - M) / frameCount;
	
	double Q = rmsObject->mLastQ;
	double Qnext = RMSMoogFilterComputeResonance(rmsObject->mResonance);
	double Qstep = (Qnext - Q) / frameCount;
	
	rmsObject->mLastM = Mnext;
	rmsObject->mLastQ = Qnext;

	// Fetch buffer pointers
	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;

	// Filter samples 
	if (S >= 88200.0)
		MoogProcessSamples1(
			M, Mstep, Q, Qstep,
			rmsObject->mL, dstPtrL,
			rmsObject->mR, dstPtrR, frameCount);
	else
		// Use oversampling routine
		MoogProcessSamples2(
			M, Mstep, Q, Qstep,
			rmsObject->mL, dstPtrL,
			rmsObject->mR, dstPtrR, frameCount);

	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
