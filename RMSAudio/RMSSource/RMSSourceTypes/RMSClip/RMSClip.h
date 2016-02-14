////////////////////////////////////////////////////////////////////////////////
/*
	RMSClip
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSClip : RMSSource

+ (instancetype) sineWaveWithLength:(UInt64)N;

- (UInt32) sampleCount;
- (float *) getPtrL;
- (float *) getPtrR;

@end
