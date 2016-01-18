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
- (void) insertFilter:(RMSSource *)filter;
- (void) removeFilter:(RMSSource *)filter;
- (void) removeFilter;

- (RMSSource *) monitor;
- (void) setMonitor:(RMSSource *)monitor;
- (void) addMonitor:(RMSSource *)monitor;
- (void) removeMonitor:(RMSSource *)monitor;
- (void) removeMonitor;

- (Float64) sampleRate;
- (void) setSampleRate:(Float64)sampleRate;

// Get the value of the corresponding objectpointers in an RMSSource
void *RMSSourceGetSource(void *source);
void *RMSSourceGetFilter(void *source);
void *RMSSourceGetMonitor(void *source);

@end

////////////////////////////////////////////////////////////////////////////////
/*
	RunRMSSource
	------------
	Run the callback of an RMSSource variant, 
	in AudioUnit parlance this would be the equivalent of AudioUnitRender
	
	Can be used in a rendercallback to produce audio from a source
*/
OSStatus RunRMSSource(
	void 							*rmsObject,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList);

////////////////////////////////////////////////////////////////////////////////







