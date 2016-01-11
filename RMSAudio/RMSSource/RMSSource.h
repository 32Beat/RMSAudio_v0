////////////////////////////////////////////////////////////////////////////////
/*
	RMSSource
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSCallback.h"

@interface RMSSource : RMSCallback
{
	Float64 mSampleRate;

	RMSSource *mSource;
	RMSSource *mFilter;
	RMSSource *mMonitor;
}

- (RMSSource *) source;
- (void) setSource:(RMSSource *)source;
- (void) addSource:(RMSSource *)source;
- (void) removeSource:(RMSSource *)source;
- (void) removeSource;

- (RMSSource *) filter;
- (void) setFilter:(RMSSource *)filter;
- (void) addFilter:(RMSSource *)filter;
- (void) removeFilter:(RMSSource *)filter;
- (void) removeFilter;

- (RMSSource *) monitor;
- (void) setMonitor:(RMSSource *)monitor;
- (void) addMonitor:(RMSSource *)monitor;
- (void) removeMonitor:(RMSSource *)monitor;
- (void) removeMonitor;

- (Float64) sampleRate;
- (void) setSampleRate:(Float64)sampleRate;

void *RMSSourceGetSource(void *source);
void *RMSSourceGetFilter(void *source);
void *RMSSourceGetMonitor(void *source);

@end

////////////////////////////////////////////////////////////////////////////////

OSStatus RunRMSSource(
	void 							*rmsObject,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList);

////////////////////////////////////////////////////////////////////////////////







