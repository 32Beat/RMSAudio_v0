////////////////////////////////////////////////////////////////////////////////
/*
	RMSMoogFilter
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSMoogFilter : RMSSource

- (void) setCutOff:(float)f;
- (void) setCutOffFrequency:(float)f;
- (void) setResonance:(float)value;
@end
