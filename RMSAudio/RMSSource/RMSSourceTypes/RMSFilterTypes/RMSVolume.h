////////////////////////////////////////////////////////////////////////////////
/*
	RMSVolume
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSVolume : RMSSource

- (float) volume;
- (void) setVolume:(float)volume;

- (float) balance;
- (void) setBalance:(float)balance;

@end
