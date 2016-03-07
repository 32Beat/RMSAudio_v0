////////////////////////////////////////////////////////////////////////////////
/*
	RMSSampleMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSSource.h"

/*
	
*/
@interface RMSSampleMonitor : RMSSource

+ (instancetype) instanceWithCount:(size_t)sampleCount;
- (instancetype) initWithCount:(size_t)sampleCount;

- (size_t) getSamples:(float **)dstPtr count:(size_t)count;

@end
