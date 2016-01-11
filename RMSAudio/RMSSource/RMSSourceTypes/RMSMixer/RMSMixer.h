////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixer
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSMixerSource.h"
#import "RMSAudioUtilities.h"

@interface RMSMixer : RMSSource
{
}

- (void) setVolume:(float)volume;
- (void) setBalance:(float)balance;

- (id) addSource:(RMSSource *)source;

@end
