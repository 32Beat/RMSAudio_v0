////////////////////////////////////////////////////////////////////////////////
/*
	RMSSineWave
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSSineWave : RMSSource

+ (instancetype) instanceWithFrequency:(double)f;
- (instancetype) initWithFrequency:(double)f;

@end
