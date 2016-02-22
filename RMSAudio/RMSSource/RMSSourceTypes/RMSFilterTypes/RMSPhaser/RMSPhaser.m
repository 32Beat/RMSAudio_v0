////////////////////////////////////////////////////////////////////////////////
/*
	RMSPhaser
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSPhaser.h"
#import <Accelerate/Accelerate.h>
#import "rmsoscillator_t.h"



@interface RMSPhaser ()
{
	rmsoscillator_t mOsc;
}

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSPhaser
////////////////////////////////////////////////////////////////////////////////

static inline void R2P(rmsoscillator_t *osc, float *srcPtrL, float *srcPtrR, size_t N)
{
	for (size_t n=0; n != N; n++)
	{
		float S1 = srcPtrL[n];
		float S2 = srcPtrR[n];

		float A = RMSOscillatorFetchSample(osc);
		
		srcPtrL[n] = A * S1;
		srcPtrR[n] = A * S2;
	}
}



static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSPhaser *rmsObject = \
	(__bridge __unsafe_unretained RMSPhaser *)inRefCon;
	
	float *srcPtrL = bufferList->mBuffers[0].mData;
	float *srcPtrR = bufferList->mBuffers[1].mData;
	
	R2P(&rmsObject->mOsc, srcPtrL, srcPtrR, frameCount);
	
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
		mOsc = RMSOscillatorBeginPseudoSineWave(.5, self.sampleRate);
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	RMSOscillatorSetSampleRate(&mOsc, sampleRate);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



