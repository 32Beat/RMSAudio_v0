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
