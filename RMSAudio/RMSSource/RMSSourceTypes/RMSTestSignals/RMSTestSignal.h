////////////////////////////////////////////////////////////////////////////////
/*
	RMSTestSignal
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSTestSignal : RMSSource

+ (instancetype) sineWaveWithFrequency:(double)f;
+ (instancetype) blockWaveWithFrequency:(double)f;
+ (instancetype) triangleWaveWithFrequency:(double)f;
+ (instancetype) sawToothWaveWithFrequency:(double)f;

+ (instancetype) instanceWithFrequency:(double)f functionPtr:(double (*)(double))ptr;

@end
