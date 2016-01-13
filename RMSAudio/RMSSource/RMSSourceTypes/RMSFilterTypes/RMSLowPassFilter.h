////////////////////////////////////////////////////////////////////////////////
/*
	RMSLowPassFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSLowPassFilter : RMSSource

- (void) setCutOff:(float)f;
- (void) setCutOffFrequency:(float)f;

@end
