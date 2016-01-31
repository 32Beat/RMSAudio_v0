////////////////////////////////////////////////////////////////////////////////
/*
	RMSCallback
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSCallback.h"



@interface RMSCallback ()

+ (instancetype) instanceWithCallbackPtr:(void *)procPtr;
- (instancetype) initWithCallbackPtr:(void *)procPtr;
+ (instancetype) instanceWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm;
- (instancetype) initWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm;
+ (instancetype) instanceWithCallbackInfo:(RMSCallbackInfo)callbackInfo;
- (instancetype) initWithCallbackInfo:(RMSCallbackInfo)callbackInfo;

+ (const RMSCallbackProcPtr) callbackPtr;
- (const RMSCallbackInfoPtr) callbackInfoPtr;

- (instancetype) initWithBlock:(RMSCallbackBlock)block;

@end



////////////////////////////////////////////////////////////////////////////////
@implementation RMSCallback
////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Callback Ptr
////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return nil; }

- (instancetype) init
{ return [self initWithCallbackPtr:[[self class] callbackPtr]]; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithCallbackPtr:(void *)procPtr
{ return [[self alloc] initWithCallbackPtr:procPtr]; }

- (instancetype) initWithCallbackPtr:(void *)procPtr
{ return [self initWithCallbackPtr:procPtr callbackPrm:(__bridge void *)self]; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm
{ return [[self alloc] initWithCallbackPtr:procPtr callbackPrm:procPrm]; }

- (instancetype) initWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm
{
	RMSCallbackInfo callbackInfo = { procPtr, procPrm };
	
	return [self initWithCallbackInfo:callbackInfo];
}

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithCallbackInfo:(RMSCallbackInfo)callbackInfo
{ return [[self alloc] initWithCallbackInfo:callbackInfo]; }

- (instancetype) initWithCallbackInfo:(RMSCallbackInfo)callbackInfo
{
	self = [super init];
	if (self != nil)
	{
		mCallbackInfo = callbackInfo;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (const RMSCallbackInfoPtr)callbackInfoPtr;
{ return &mCallbackInfo; }

const RMSCallbackInfo *RMSCallbackGetInfoPtr(void *rmsSource)
{ return &((__bridge __unsafe_unretained RMSCallback *)rmsSource)->mCallbackInfo; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark 
#pragma mark Block Ptr
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*ioActionFlags,
	const AudioTimeStamp 			*inTimeStamp,
	UInt32							inBusNumber,
	UInt32							frameCount,
	AudioBufferList 				*audio)
{
	__unsafe_unretained RMSCallback *rmsSource =
	(__bridge __unsafe_unretained RMSCallback *)inRefCon;

	PCMSampleRange R = { inTimeStamp->mSampleTime, frameCount };
	return rmsSource->mCallbackBlock(R, audio);
}

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithBlock:(RMSCallbackBlock)block
{ return [[self alloc] initWithBlock:block]; }

- (instancetype) initWithBlock:(RMSCallbackBlock)block
{
	self = [self initWithCallbackPtr:renderCallback];
	if (self != nil)
	{
		mCallbackBlock = block;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
#pragma mark
////////////////////////////////////////////////////////////////////////////////

OSStatus RMSCallbackRun(
	void *rmsCallbackObject,
	PCMSampleRange sampleRange,
	AudioBufferList *bufferList)
{
	__unsafe_unretained RMSCallback *rmsCallback =
	(__bridge __unsafe_unretained RMSCallback *)rmsCallbackObject;
	
	return rmsCallback != nil ?
	RMSCallbackInfoRun(&rmsCallback->mCallbackInfo, sampleRange, bufferList) : noErr;
}

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
