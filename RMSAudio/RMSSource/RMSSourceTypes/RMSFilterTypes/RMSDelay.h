////////////////////////////////////////////////////////////////////////////////
/*
	RMSDelay
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSDelay : RMSSource

- (float) delayTime;
- (void) setDelayTime:(float)time;

- (float) feedBack;
- (void) setFeedBack:(float)value;

@end
