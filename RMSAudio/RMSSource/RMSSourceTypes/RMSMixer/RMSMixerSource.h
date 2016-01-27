////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixerSource
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSAudioUtilities.h"

@interface RMSMixerSource : RMSSource

+ (instancetype) instanceWithSource:(RMSSource *)source;
- (instancetype) initWithSource:(RMSSource *)source;

- (float) volume;
- (void) setVolume:(float)volume;
- (float) balance;
- (void) setBalance:(float)balance;

- (RMSMixerSource *) nextMixerSource;
- (void) setNextMixerSource:(RMSMixerSource *)source;
- (void) addNextMixerSource:(RMSMixerSource *)source;
- (void) removeNextMixerSource:(RMSMixerSource *)source;

float RMSMixerSourceGetLastVolume(void *source);
void *RMSMixerSourceGetNextSource(void *source);

@end

