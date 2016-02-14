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
	5. if not 0, communicate current trashcount to main
	6. on main, remove count items and update thrashCount
*/
@interface RMSSource ()
{
	NSMutableArray *mTrashItems;
	NSUInteger mTrashCount;
	NSUInteger mTrashSeen;
	NSTimer *mTrashTimer;
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
		
		[self updateTrash:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	updateTrash
	-----------
	Update trasharray and counters
	
	updateTrash is called both when a new object is added to the trash, 
	or when an optional timer fires from a previous call. 
	
	mTrashCount is a flag to indicate to the audiothread the number of objects 
	in the trashArray, so the audiothread won't have to call obj-c methods.
 
	mTrashSeen is a flag to subsequently indicate to the mainthread the number 
	of objects that are safe to be deleted.
	
	note 1: 
	mTrashCount needs to be updated to [mTrashItems count]
	mTrashSeen may only be reset if it was not zero previously
	in order to keep the code confined, it is updated as per
	the sequence seen below
*/
- (void) updateTrash:(id)sender
{
	// Reset timer if necessary
	if (mTrashTimer == sender)
	{ mTrashTimer = nil; }
	
	// As long as mTrashSeen != 0, we can safely manipulate trash
	if (mTrashSeen != 0)
	{
		// Remove number of objects seen by audio thread
		for (NSUInteger n=mTrashSeen; n!=0; n--)
		{ [mTrashItems removeLastObject]; }

		// Reset counters ** See note 1 **
		mTrashCount = 0;
		mTrashSeen = 0;
	}
	
	// Try emptying more trash later if necessary
	mTrashCount = [mTrashItems count];
	if (mTrashCount != 0)
	{
		if (mTrashTimer != nil)
		{
			mTrashTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
			target:self selector:@selector(updateTrash:) userInfo:nil repeats:NO];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Handled on main
/*
static void TrashCallback(void *rmsObject, NSUInteger count)
{ [(__bridge RMSSource *)rmsObject emptyTrash:count]; }

////////////////////////////////////////////////////////////////////////////////
// Handled on audio thread

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
*/
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


	// Communicate prerender trash count to main
	if (rmsSource->mTrashCount != 0)
	{
		if (rmsSource->mTrashSeen == 0)
		{
			rmsSource->mTrashSeen = rmsSource->mTrashCount;
		}
	}


	OSStatus result = noErr;

	// Run the callback for self
	result = RunRMSCallback(&rmsSource->mCallbackInfo,
	actionFlags, timeStamp, busNumber, frameCount, bufferList);
	if (result != noErr) return result;
	
	// Run the filter (chain)
	if (rmsSource->mFilter != nil)
	{
		result = RunRMSSource((__bridge void *)rmsSource->mFilter,
		actionFlags, timeStamp, busNumber, frameCount, bufferList);
		if (result != noErr) return result;
	}
	
	// Run the monitor (chain)
	if (rmsSource->mMonitor != nil)
	{
		result = RunRMSSource((__bridge void *)rmsSource->mMonitor,
		actionFlags, timeStamp, busNumber, frameCount, bufferList);
		if (result != noErr) return result;
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

- (void) insertFilter:(RMSSource *)filter
{
	if (mFilter != nil)
	{ [filter addFilter:mFilter]; }
	mFilter = filter;
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
