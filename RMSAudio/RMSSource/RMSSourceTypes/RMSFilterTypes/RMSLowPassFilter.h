////////////////////////////////////////////////////////////////////////////////
/*
	RMSLowPassFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"


@interface RMSLowPassFilter : RMSSource
{
	double mFrequency;
	double mResonance;
}

- (void) setCutOff:(float)f;

- (float) frequency;
- (void) setFrequency:(float)f;
- (float) resonance;
- (void) setResonance:(float)value;

@end

static inline float HardClip(float x) \
{ return -1.0 < x ? x < +1.0 ? x : +1.0 : -1.0; }

//static inline float SoftClip(float x) \
{ return -1.5 < x ? x < +1.5 ? x -(4.0/27.0)*x*x*x : +1.0 : -1.0; }
