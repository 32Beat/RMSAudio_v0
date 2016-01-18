////////////////////////////////////////////////////////////////////////////////
/*
	RMSMoogFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSMoogFilter.h"


static inline float HardClip(float x) \
{ return -1.0 < x ? x < +1.0 ? x : +1.0 : -1.0; }

static inline float SoftClip(float x) \
{ return -1.5 < x ? x < +1.5 ? x -(4.0/27.0)*x*x*x : +1.0 : -1.0; }


typedef struct rmsmoogfilter_t
{
	float F;
	float M;
	float Q;
	
	float A[8];
}
rmsmoogfilter_t;





@interface RMSMoogFilter ()
{
	double mLastM;
	double mLastQ;
	
	double mL[8];
	double mR[8];
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSMoogFilter
////////////////////////////////////////////////////////////////////////////////

static inline double MoogProcessSample(double M, double Q, double *A, double S)
{
	A[4] += 0.5*(A[3]-A[4]);
	
	S -= Q * A[4];
	S = HardClip(S);
	
	A[0] += M * (S   -A[0]);
	A[1] += M * (A[0]-A[1]);
	A[2] += M * (A[1]-A[2]);
	A[3] += M * (A[2]-A[3]);

//	A[3] = SoftClip(A[3]);
	
	return A[3];
}

////////////////////////////////////////////////////////////////////////////////

static inline void MoogProcessSamples(
	double M, double Mstep,
	double Q, double Qstep,
	double *AL, float *ptrL,
	double *AR, float *ptrR,
	UInt32 frameCount)
{	
	do
	{
		AL[0] += ptrL[0];
		AL[0] *= 0.5;
		double L = MoogProcessSample(M, Q, &AL[1], AL[0]);

		AR[0] += ptrR[0];
		AR[0] *= 0.5;
		double R = MoogProcessSample(M, Q, &AR[1], AR[0]);
		
		M += Mstep;
		Q += Qstep;
		
		AL[0] = ptrL[0];
		L += MoogProcessSample(M, Q, &AL[1], AL[0]);
		AR[0] = ptrR[0];
		R += MoogProcessSample(M, Q, &AR[1], AR[0]);
		
		*ptrL++ = 0.5*L;
		*ptrR++ = 0.5*R;
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
	if (rmsObject->mLastM == 0.0)
	{ rmsObject->mLastM = rmsObject->mFrequency * 2.0 / S; }

	double M = rmsObject->mLastM;
	double Mnext = rmsObject->mFrequency * 2.0 / S;
	double Mstep = (Mnext - M) / frameCount;
	
	double Q = rmsObject->mLastQ;
	double Qnext = rmsObject->mResonance * 4.0;
	double Qstep = (Qnext - Q) / frameCount;
	
	rmsObject->mLastM = Mnext;
	rmsObject->mLastQ = Qnext;

	// Fetch buffer pointers
	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;

	// Filter samples 
	MoogProcessSamples(
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
