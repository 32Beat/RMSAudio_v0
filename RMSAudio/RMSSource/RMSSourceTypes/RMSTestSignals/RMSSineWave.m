////////////////////////////////////////////////////////////////////////////////
/*
	RMSSineWave
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSineWave.h"


@interface RMSSineWave ()
{
	double mFrequency;
	double mX2PI;
	double mStep;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSineWave
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							frameCount,
	AudioBufferList 				*audio)
{
	__unsafe_unretained RMSSineWave *rmsSource = \
	(__bridge __unsafe_unretained RMSSineWave *)inRefCon;

	Float32 *srcPtr1 = audio->mBuffers[0].mData;
	Float32 *srcPtr2 = audio->mBuffers[1].mData;
		
	for (UInt32 n=0; n!=frameCount; n++)
	{
		Float32 Y = sin(rmsSource->mX2PI);
		srcPtr1[n] = Y;
		srcPtr2[n] = Y;
		
		rmsSource->mX2PI += rmsSource->mStep;
		if (rmsSource->mX2PI > M_PI)
		{ rmsSource->mX2PI -= (M_PI+M_PI); }
	}

	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{ return [self initWithFrequency:441.0]; }

+ (instancetype) instanceWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f]; }

- (instancetype) initWithFrequency:(double)f
{
	self = [super init];
	if (self != nil)
	{
		mFrequency = f;
		// Initialize with reasonable default
		[self setSampleRate:44100.0];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	mStep = mSampleRate ? mFrequency * 2.0 * M_PI / mSampleRate : 0.0;
	mX2PI = 0.5 * mStep;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////







