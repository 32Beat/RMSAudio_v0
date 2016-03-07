////////////////////////////////////////////////////////////////////////////////
/*
	RMSAutoPan
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSMonitor.h"

@interface RMSAutoPan : RMSSource

+ (instancetype) instanceWithSampleRate:(Float64)sampleRate;
+ (instancetype) instanceWithSampleRate:(Float64)sampleRate responseTime:(NSTimeInterval)responseTime;
- (instancetype) initWithSampleRate:(Float64)sampleRate responseTime:(NSTimeInterval)responseTime;

- (float) correctionBalance;

@end
