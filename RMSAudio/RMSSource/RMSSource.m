////////////////////////////////////////////////////////////////////////////////
/*
	RMSSource
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSSource.h"
#import "RMSAudioUtilities.h"
#import "RMSAudio.h"

////////////////////////////////////////////////////////////////////////////////
/*
	Multithreading:
	Adding an object to the rendertree is not generally a problem
	Removing an object however is a problem requiring careful consideration.
 
	Strategy for removing objects from the rendertree:
	1. remove the object from the RMSSource connection, 
	2. add it to the trash array
	3. increase thrashCount
	
	4. renderCallback checks thrashCount prior to rendering,
	5. if not 0, dispatch a block to main with that particular count
	6. on main, remove count items and update thrashCount
*/
@interface RMSSource ()
{
	BOOL mTrashBusy;
	NSUInteger mTrashCount;
	NSMutableArray *mTrashItems;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSSource
////////////////////////////////////////////////////////////////////////////////

- (void) trashObject:(id)object
{
	if (object != nil)
	{
		if (mTrashItems == nil)
		{ mTrashItems = [NSMutableArray new]; }
		[mTrashItems insertObject:object atIndex:0];
		mTrashCount += 1;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) emptyTrash:(NSUInteger)count
{
	for (; count!=0; count--)
	{ [mTrashItems removeLastObject]; }
	mTrashCount = [mTrashItems count];
	mTrashBusy = NO;
}

////////////////////////////////////////////////////////////////////////////////

static void TrashCallback(void *rmsObject, NSUInteger count)
{ [(__bridge RMSSource *)rmsObject emptyTrash:count]; }

////////////////////////////////////////////////////////////////////////////////

static void HandleTrash(void *rmsObject)
{
	__unsafe_unretained RMSSource *rmsSource =
	(__bridge __unsafe_unretained RMSSource *)rmsObject;

	if (rmsSource->mTrashBusy == NO)
	{
		rmsSource->mTrashBusy = YES;
		
		NSUInteger trashCount = rmsSource->mTrashCount;
		dispatch_async(dispatch_get_main_queue(),
		^{ TrashCallback(rmsObject, trashCount); });
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

OSStatus RunRMSSource(
	void 							*rmsObject,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSSource *rmsSource =
	(__bridge __unsafe_unretained RMSSource *)rmsObject;


	// Empty any trash on main
	if (rmsSource->mTrashCount != 0)
	{ HandleTrash(rmsObject); }


	OSStatus result = RunRMSCallback(&rmsSource->mCallbackInfo,
	actionFlags, timeStamp, busNumber, frameCount, bufferList);
	if (result != noErr)
		return result;
	
	if (rmsSource->mFilter != nil)
	{
		result = RunRMSSource((__bridge void *)rmsSource->mFilter,
		actionFlags, timeStamp, busNumber, frameCount, bufferList);
		if (result != noErr)
			return result;
	}
	
	if (rmsSource->mMonitor != nil)
	{
		result = RunRMSSource((__bridge void *)rmsSource->mMonitor,
		actionFlags, timeStamp, busNumber, frameCount, bufferList);
		if (result != noErr)
			return result;
	}
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

void *RMSSourceGetSource(void *source)
{ return (__bridge void *)((__bridge RMSSource *)source)->mSource; }

void *RMSSourceGetFilter(void *source)
{ return (__bridge void *)((__bridge RMSSource *)source)->mFilter; }

void *RMSSourceGetMonitor(void *source)
{ return (__bridge void *)((__bridge RMSSource *)source)->mMonitor; }

////////////////////////////////////////////////////////////////////////////////

- (RMSSource *) source
{ return mSource; }

- (RMSSource *) filter
{ return mFilter; }

- (RMSSource *) monitor
{ return mMonitor; }

////////////////////////////////////////////////////////////////////////////////

- (void) setSource:(RMSSource *)source
{
	if (mSource != source)
	{
		id oldSource = mSource;
		
		mSource = source;

		[self trashObject:oldSource];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) addSource:(RMSSource *)source
{
	if (mSource == nil)
	{ mSource = source; }
	else
	{ [mSource addSource:source]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeSource:(RMSSource *)source
{
	if (mSource == source)
	{ [self removeSource]; }
	else
	{ [mSource removeSource:source]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeSource
{
	if (mSource != nil)
	{ [self setSource:[mSource source]]; }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark 
////////////////////////////////////////////////////////////////////////////////

- (void) setFilter:(RMSSource *)filter
{
	if (mFilter != filter)
	{
		id oldFilter = mFilter;
		
		[filter setSampleRate:[self sampleRate]];
		mFilter = filter;
		
		[self trashObject:oldFilter];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) addFilter:(RMSSource *)filter
{
	if (self == filter)
	{ NSLog(@"%@", @"addFilter error!"); return; }
	
	if (mFilter == nil)
	{ [self setFilter:filter]; }
	else
	{ [mFilter addFilter:filter]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeFilter:(RMSSource *)filter
{
	if (mFilter == filter)
	{ [self removeFilter]; }
	else
	{ [mFilter removeFilter:filter]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeFilter
{
	if (mFilter != nil)
	{ [self setFilter:[mFilter filter]]; }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark 
////////////////////////////////////////////////////////////////////////////////

- (void) setMonitor:(RMSSource *)monitor
{
	if (mMonitor != monitor)
	{
		id oldMonitor = mMonitor;
		
		[monitor setSampleRate:[self sampleRate]];
		mMonitor = monitor;
		
		[self trashObject:oldMonitor];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) addMonitor:(RMSSource *)monitor
{
	if (self == monitor)
	{ NSLog(@"%@", @"addMonitor error!"); return; }

	if (mMonitor == nil)
	{ [self setMonitor:monitor]; }
	else
	{ [mMonitor addMonitor:monitor]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeMonitor:(RMSSource *)monitor
{
	if (mMonitor == monitor)
	{ [self removeMonitor]; }
	else
	{ [mMonitor removeMonitor:monitor]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeMonitor
{
	if (mMonitor != nil)
	{ [self setMonitor:[mMonitor monitor]]; }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (Float64) sampleRate
{ return mSampleRate != 0.0 ? mSampleRate : 44100.0; }

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	if (mSampleRate != sampleRate)
	{
		mSampleRate = sampleRate;
		//[mSource setSampleRate:sampleRate];
		[mFilter setSampleRate:sampleRate];
		[mMonitor setSampleRate:sampleRate];
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
