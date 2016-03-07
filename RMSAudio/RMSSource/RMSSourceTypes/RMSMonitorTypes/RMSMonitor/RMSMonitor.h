////////////////////////////////////////////////////////////////////////////////
/*
	RMSMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "rmslevels.h"

@interface RMSMonitor : RMSSource

+ (instancetype) instanceWithSampleRate:(Float64)sampleRate;
- (instancetype) initWithSampleRate:(Float64)sampleRate;

- (const rmsengine_t *) enginePtrL;
- (const rmsengine_t *) enginePtrR;

- (rmsresult_t) resultLevelsL;
- (rmsresult_t) resultLevelsR;
- (double) resultBalance;

@end
