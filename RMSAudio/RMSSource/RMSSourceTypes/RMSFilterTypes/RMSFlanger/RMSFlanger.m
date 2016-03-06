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


// UNDER CONSTRUCTION

////////////////////////////////////////////////////////////////////////////////
// TODO: probably merits separate file
typedef struct rmsflanger_t
{
	rmsdelay_t delay;
	rmsoscillator_t lfo;
	double sampleRate;
	double time;
	double depth;
}
rmsflanger_t;



#define MAX_FLANGER_DELAY_TIME (0.01)
// 2048 samples is a little over 0.01 sec @ 192k
#define MAX_FLANGER_DELAY_SIZE (1<<11)

/*
	Notes:
	for flanging, the LPF property of linear interpolation is desireable.
	for other effects like chorus, it is probably preferred to use Lanczos
	
	modulation freq: 
	because of squared sine, freq needs to be half the usersetting
*/
rmsflanger_t RMSFlangerBegin(void)
{
	static double Hz = 0.05;
	static double Ph = 0.0;
	
	return (rmsflanger_t)
	{
		.delay = RMSDelayBeginWithSize(MAX_FLANGER_DELAY_SIZE),
		.lfo = RMSOscillatorBeginPseudoSineWave(Hz, (Ph+=0.5)),
		.sampleRate = 44100,
		.time = 0.003,
		.depth = 0.5,
	};
}

void RMSFlangerEnd(rmsflanger_t *flanger)
{
	RMSDelayEnd(&flanger->delay);
}

void RMSFlangerSetSampleRate(rmsflanger_t *flanger, double sampleRate)
{
	RMSOscillatorSetSampleRate(&flanger->lfo, sampleRate);
}

void RMSFlangerSetMaxDetune(rmsflanger_t *flanger, double cents)
{
//	double minStep = pow(2.0, -cents/1200.0);
	double maxStep = pow(2.0, +cents/1200.0);
	double Hz = (maxStep-1.0) / flanger->time;
	RMSOscillatorSetFrequency(&flanger->lfo, Hz);
}



static double Bezier
(double x, double P1, double C1, double C2, double P2)
{
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);
	C2 += x * (P2 - C2);
	
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);

	P1 += x * (C1 - P1);

	return P1;
}

////////////////////////////////////////////////////////////////////////////////

static double CRCompute
(double a, double x, double Y0, double Y1, double Y2, double Y3)
{
	double d1 = a * (Y2 - Y0) / 2.0;
	double d2 = a * (Y3 - Y1) / 2.0;
	return Bezier(x, Y1, Y1+d1, Y2-d2, Y2);
}

////////////////////////////////////////////////////////////////////////////////

float RMSFlangerProcessSample(rmsflanger_t *flanger, double delay, double depth, float S)
{
	// Store incoming sample first, so we can have true 0.0 delay
	RMSBufferWriteSample(&flanger->delay, S);

	// fetch lfo value for delay modulation
	double D = RMSOscillatorFetchSample(&flanger->lfo);

	D *= D;
	D *= delay;

	double R = RMSBufferGetValueWithDelayCR(&flanger->delay, D);

	S += depth * (R - S);

	return S;
}

////////////////////////////////////////////////////////////////////////////////
// TODO: utility function so we don't write this
typedef struct rmsvalue_t
{
	double lastValue;
	double stepValue;
}
rmsvalue_t;

void RMSValueSetNextValue(rmsvalue_t *ptr, double value, UInt32 frameCount)
{ ptr->stepValue = (value - ptr->lastValue)/frameCount; }

double RMSValueGetNextValue(rmsvalue_t *ptr)
{ return (ptr->lastValue += ptr->stepValue); }

////////////////////////////////////////////////////////////////////////////////



@interface RMSFlanger ()
{
	double mTimeInSamples;
	rmsvalue_t mEngineTimeInSamples;
	rmsvalue_t mEngineDepth;
	
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
	
	rmsvalue_t *currentDelay = &rmsObject->mEngineTimeInSamples;
	RMSValueSetNextValue(currentDelay, rmsObject->mTimeInSamples, frameCount);

	rmsvalue_t *currentDepth = &rmsObject->mEngineDepth;
	RMSValueSetNextValue(currentDepth, rmsObject->_depth, frameCount);
	
	for (UInt32 n=0; n!=frameCount; n++)
	{
		double delay = RMSValueGetNextValue(currentDelay);
		double depth = RMSValueGetNextValue(currentDepth);
		ptrL[n] = RMSFlangerProcessSample(&rmsObject->mFlangerL, delay, depth, ptrL[n]);
		ptrR[n] = RMSFlangerProcessSample(&rmsObject->mFlangerR, delay, depth, ptrR[n]);
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
		_delay = 0.003;
		_delayModulation = 0.1;
		_depth = 0.5;
		
		mFlangerL = RMSFlangerBegin();
		mFlangerR = RMSFlangerBegin();
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

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];
	RMSFlangerSetSampleRate(&mFlangerL, sampleRate);
	RMSFlangerSetSampleRate(&mFlangerR, sampleRate);
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDelay:(float)value
{
	if (value > 1.0) value = 1.0;

	if (_delay != value)
	{
		_delay = value;
		mTimeInSamples = _delay * MAX_FLANGER_DELAY_TIME * self.sampleRate;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDelayModulation:(float)value
{
	if (value > 1.0) value = 1.0;
	
	if (_delayModulation != value)
	{
		_delayModulation = value;

//	RMSFlangerSetMaxDetune(&mFlangerL, 1200*value);
//	RMSFlangerSetMaxDetune(&mFlangerR, 1200*value);

		float Hz = pow(10.0, -1.0 + 2.0 * value);
		RMSOscillatorSetFrequency(&mFlangerL.lfo, Hz);
		RMSOscillatorSetFrequency(&mFlangerR.lfo, Hz);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) setDepth:(float)value
{
	if (value > 1.0) value = 1.0;
	
	if (_depth != value)
	{
		_depth = value;
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



