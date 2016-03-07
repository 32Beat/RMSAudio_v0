////////////////////////////////////////////////////////////////////////////////
/*
	RMSSampleMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSampleMonitor.h"
#import "rmsbuffer_t.h"
#import <Accelerate/Accelerate.h>






@interface RMSSampleMonitor ()
{
	size_t mCount;
	rmsbuffer_t mBufferL;
	rmsbuffer_t mBufferR;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSampleMonitor
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSSampleMonitor *rmsObject = \
	(__bridge __unsafe_unretained RMSSampleMonitor *)inRefCon;
	
	float *srcPtrL = bufferList->mBuffers[0].mData;
	RMSBufferWriteSamples(&rmsObject->mBufferL, srcPtrL, frameCount);

	float *srcPtrR = bufferList->mBuffers[1].mData;
	RMSBufferWriteSamples(&rmsObject->mBufferR, srcPtrR, frameCount);
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithCount:(size_t)size
{ return [[self alloc] initWithCount:size]; }

- (instancetype) init
{ return [self initWithCount:1024]; }

- (instancetype) initWithCount:(size_t)sampleCount
{
	self = [super init];
	if (self != nil)
	{
		sampleCount = 1<<(int)(round(log2(sampleCount)));
		
		mCount = sampleCount;
		mBufferL = RMSBufferBegin(sampleCount);
		mBufferR = RMSBufferBegin(sampleCount);
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSBufferEnd(&mBufferL);
	RMSBufferEnd(&mBufferR);
}

////////////////////////////////////////////////////////////////////////////////

- (size_t) getSamples:(float **)dstPtr count:(size_t)count
{
	uint64_t indexL = mBufferL.index;
	uint64_t indexR = mBufferR.index;
	uint64_t index = indexL < indexR ? indexL : indexR;
	
	index -= count;
	RMSBufferReadSamplesFromIndex(&mBufferL, index, dstPtr[0], count);
	RMSBufferReadSamplesFromIndex(&mBufferR, index, dstPtr[1], count);
	
	return count;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



