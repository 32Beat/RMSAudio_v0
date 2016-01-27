////////////////////////////////////////////////////////////////////////////////
/*
	RMSTestSignal
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSTestSignal.h"


@interface RMSTestSignal ()
{
	double mFrequency;
	
	double mX;
	double mStep;
	
	double (*mFunctionPtr)(double);
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSTestSignal
////////////////////////////////////////////////////////////////////////////////
/*
	x modulates between [-1.0, ..., +1.0)
*/
static double sineWave(double x)
{ return sin(x*M_PI); }

static double blockWave(double x)
{ return x < 0.0 ? -1.0 : +1.0; }

static double triangleWave(double x)
{ return x < 0.0 ? x + x + 1.0 : 1.0 - x - x; }

static double sawToothWave(double x)
{ return x; }


static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							frameCount,
	AudioBufferList 				*audio)
{
	__unsafe_unretained RMSTestSignal *rmsSource = \
	(__bridge __unsafe_unretained RMSTestSignal *)inRefCon;

	Float32 *srcPtr1 = audio->mBuffers[0].mData;
	Float32 *srcPtr2 = audio->mBuffers[1].mData;
	
	for (UInt32 n=0; n!=frameCount; n++)
	{
		rmsSource->mX += rmsSource->mStep;
		if (rmsSource->mX >= 1.0)
		{ rmsSource->mX -= 2.0; }

		double Y = rmsSource->mFunctionPtr(rmsSource->mX);
		srcPtr1[n] = Y;
		srcPtr2[n] = Y;
	}
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) sineWaveWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f functionPtr:sineWave]; }

+ (instancetype) blockWaveWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f functionPtr:blockWave]; }

+ (instancetype) triangleWaveWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f functionPtr:triangleWave]; }

+ (instancetype) sawToothWaveWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f functionPtr:sawToothWave]; }

+ (instancetype) instanceWithFrequency:(double)f functionPtr:(double (*)(double))ptr
{ return [[self alloc] initWithFrequency:f functionPtr:ptr]; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{ return [self initWithFrequency:441.0 functionPtr:nil]; }

+ (instancetype) instanceWithFrequency:(double)f
{ return [[self alloc] initWithFrequency:f functionPtr:nil]; }

- (instancetype) initWithFrequency:(double)f functionPtr:(double (*)(double))ptr
{
	self = [super init];
	if (self != nil)
	{
		mFrequency = f;
		mFunctionPtr = ptr ? ptr : sineWave;

		// Initialize with reasonable default
		[self setSampleRate:44100.0];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	mStep = mSampleRate ? 2.0 * mFrequency / mSampleRate : 0.0;
	mX = 0.5 * mStep;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////







