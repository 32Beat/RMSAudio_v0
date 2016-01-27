////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixerSource
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSMixerSource.h"
#import "RMSAudioUtilities.h"

#import "RMSVolume.h"

@interface RMSMixerSource ()
{
	RMSVolume *mVolumeFilter;

	RMSMixerSource *mNextMixerSource;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSMixerSource
////////////////////////////////////////////////////////////////////////////////

void *RMSMixerSourceGetNextSource(void *source)
{ return (__bridge void *)((__bridge RMSMixerSource *)source)->mNextMixerSource; }

void *RMSMixerSourceGetVolumeFilter(void *source)
{ return (__bridge void *)((__bridge RMSMixerSource *)source)->mVolumeFilter; }

float RMSMixerSourceGetLastVolume(void *source)
{ return RMSVolumeGetLastVolume(RMSMixerSourceGetVolumeFilter(source)); }

////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							frameCount,
	AudioBufferList 				*tmpBuffer)
{
	__unsafe_unretained RMSMixerSource *rmsSource = \
	(__bridge __unsafe_unretained RMSMixerSource *)inRefCon;
 
	// Render source into temp buffer
	return RunRMSSource((__bridge void *)rmsSource->mSource,
	ioActionFlags, inTimeStamp, inBusNumber, frameCount, tmpBuffer);
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{
	self = [super init];
	if (self != nil)
	{
		mVolumeFilter = [RMSVolume new];
		[self addFilter:mVolumeFilter];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithSource:(RMSSource *)source
{ return [[self alloc] initWithSource:source]; }

- (instancetype) initWithSource:(RMSSource *)source
{
	self = [super init];
	if (self != nil)
	{
		mVolumeFilter = [RMSVolume new];
		[self addFilter:mVolumeFilter];
		[self addSource:source];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (float) volume
{ return mVolumeFilter.volume; }

- (void) setVolume:(float)volume
{ mVolumeFilter.volume = volume; }

- (float) balance
{ return mVolumeFilter.balance; }

- (void) setBalance:(float)balance
{ mVolumeFilter.balance = balance; }

////////////////////////////////////////////////////////////////////////////////

- (RMSMixerSource *) nextMixerSource
{ return mNextMixerSource; }

- (void) setNextMixerSource:(RMSMixerSource *)source
{
	if (mNextMixerSource != source)
	{
		id oldSource = mSource;
		
		mNextMixerSource = source;

		[self trashObject:oldSource];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) addNextMixerSource:(RMSMixerSource *)source
{
	if (mNextMixerSource == nil)
	{ mNextMixerSource = source; }
	else
	{ [mNextMixerSource addNextMixerSource:source]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeNextMixerSource:(RMSMixerSource *)source
{
	if (mNextMixerSource == source)
	{ [self removeNextMixerSource]; }
	else
	{ [mNextMixerSource removeNextMixerSource:source]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeNextMixerSource
{
	if (mNextMixerSource != nil)
	{ [self setNextMixerSource:[mNextMixerSource nextMixerSource]]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[mSource setSampleRate:sampleRate];
	[super setSampleRate:sampleRate];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
