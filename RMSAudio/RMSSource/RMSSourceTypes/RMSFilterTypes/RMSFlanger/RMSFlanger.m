////////////////////////////////////////////////////////////////////////////////
/*
	RMSFlanger
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSFlanger.h"
#import "rmsdelay_t.h"
#import "rmsoscillator_t.h"
#import <Accelerate/Accelerate.h>


typedef struct rmsflanger_t
{
	rmsdelay_t delay;
	rmsoscillator_t lfo;
	double depth;
}
rmsflanger_t;

rmsflanger_t RMSFlangerBegin(void)
{
	return (rmsflanger_t)
	{
		.delay = RMSDelayBeginWithSize(128),
		.lfo = RMSOscillatorBeginPseudoSineWave(.1, 44100.0),
		.depth = 0.5
	};
}

void RMSFlangerEnd(rmsflanger_t *flanger)
{
	RMSDelayEnd(&flanger->delay);
}

float RMSFlangerProcessSample(rmsflanger_t *flanger, float S)
{
	float D = (1.0 + RMSOscillatorFetchSample(&flanger->lfo));
	if (D < 0.0)
	{
		D = 0.0;
	}
	else
	if (D > +2.0)
	{
		D = +2.0;
	}

	// First write current sample so we can get a 0.0 delay
	RMSBufferWriteSample(&flanger->delay, S);
	
	// index is updated, so 0.0 delay, is actually 1.0
	
	//float R = RMSBufferGetSampleWithDelay(&flanger->delay, 1+round(32*D));
	float R = RMSBufferGetValueWithDelay(&flanger->delay, 1 + 63*D);
	
	
	return S + flanger->depth * (R - S);
}

@interface RMSFlanger ()
{
	rmsflanger_t mFlangerL;
	rmsflanger_t mFlangerR;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSFlanger
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSFlanger *rmsObject = \
	(__bridge __unsafe_unretained RMSFlanger *)inRefCon;
	
	float *ptrL = bufferList->mBuffers[0].mData;
	float *ptrR = bufferList->mBuffers[1].mData;
	
	for (UInt32 n=0; n!=frameCount; n++)
	{
		ptrL[n] = RMSFlangerProcessSample(&rmsObject->mFlangerL, ptrL[n]);
		ptrR[n] = RMSFlangerProcessSample(&rmsObject->mFlangerR, ptrR[n]);
	}
	
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
		mFlangerL = RMSFlangerBegin();
		mFlangerR = RMSFlangerBegin();
		
		RMSOscillatorSetFrequency(&mFlangerL.lfo, 0.15);
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSFlangerEnd(&mFlangerL);
	RMSFlangerEnd(&mFlangerR);
}

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



