////////////////////////////////////////////////////////////////////////////////
/*
	RMSDelay
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSDelay : RMSSource

- (void) setDelay:(float)delay;

- (NSTimeInterval) delayTime;
- (void) setDelayTime:(NSTimeInterval)time;

- (float) feedBack;
- (void) setFeedBack:(float)value;

- (float) mix;
- (void) setMix:(float)value;

@end
