////////////////////////////////////////////////////////////////////////////////
/*
	RMSDelay
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSDelay.h"
#import "rmsdelay_t.h"


@interface RMSDelay ()
{
	float mTime;
	float mFeedBack;
	
	rmsdelay_t mDelayL;
	rmsdelay_t mDelayR;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSDelay
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSDelay *rmsObject = \
	(__bridge __unsafe_unretained RMSDelay *)inRefCon;

	float *dstPtrL = bufferList->mBuffers[0].mData;
	float *dstPtrR = bufferList->mBuffers[1].mData;

	float nextDelay = rmsObject->mTime * rmsObject->mSampleRate;
	if (nextDelay > (1024*1024))
	{ nextDelay = 1024*1024; }

	float nextFeedBack = rmsObject->mFeedBack;

	RMSDelayProcessSamples(&rmsObject->mDelayL, nextDelay, nextFeedBack, dstPtrL, frameCount);
	RMSDelayProcessSamples(&rmsObject->mDelayR, nextDelay, nextFeedBack, dstPtrR, frameCount);
	
	return noErr;
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
		mDelayL = RMSDelayNew();
		mDelayR = RMSDelayNew();
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSDelayReleaseMemory(&mDelayL);
	RMSDelayReleaseMemory(&mDelayR);
}

////////////////////////////////////////////////////////////////////////////////

- (float) delayTime
{ return mTime; }

- (void) setDelayTime:(float)time
{ mTime = pow(10, -4 + 5 * time); }

////////////////////////////////////////////////////////////////////////////////

- (float) feedBack
{ return mFeedBack; }

- (void) setFeedBack:(float)value
{ mFeedBack = value; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////










