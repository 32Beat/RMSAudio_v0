////////////////////////////////////////////////////////////////////////////////
/*
	RMSCallback
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////

typedef struct PCMSampleRange
{
	SInt64 index;
	SInt64 count;
}
PCMSampleRange;


typedef AURenderCallback RMSCallbackProcPtr;

typedef void *RMSCallbackPtr;
typedef void *RMSCallbackPrm;

typedef struct RMSCallbackInfo RMSCallbackInfo;

struct RMSCallbackInfo
{
	void *procPtr;
	void *procPrm;

	UInt32 flags;
	const RMSCallbackInfo *nextCallbackInfo;
};

////////////////////////////////////////////////////////////////////////////////

static inline OSStatus RunRMSCallback(
	const RMSCallbackInfo 			*callbackInfo,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	return ((AURenderCallback)callbackInfo->procPtr)(callbackInfo->procPrm,
	actionFlags, timeStamp, busNumber, frameCount, bufferList);
}

////////////////////////////////////////////////////////////////////////////////

static inline OSStatus RunRMSCallbackChain(
	const RMSCallbackInfo 			*callbackInfo,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	while (callbackInfo != nil)
	{
		OSStatus result = RunRMSCallback(callbackInfo,
		actionFlags, timeStamp, busNumber, frameCount, bufferList);
		if (result != noErr) return result;
		
		callbackInfo = callbackInfo->nextCallbackInfo;
	}
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

static inline OSStatus RMSCallbackInfoRun(
	const RMSCallbackInfo *callbackInfo,
	PCMSampleRange sampleRange,
	AudioBufferList *bufferList)
{
	AudioUnitRenderActionFlags actionFlags = 0;

	AudioTimeStamp timeStamp;
	memset(&timeStamp, 0, sizeof(timeStamp));
	
	timeStamp.mSampleTime = sampleRange.index;
	timeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	
	return ((AURenderCallback)callbackInfo->procPtr)(callbackInfo->procPrm,
	&actionFlags, &timeStamp, 0, (UInt32)sampleRange.count, bufferList);
}

////////////////////////////////////////////////////////////////////////////////

OSStatus RMSCallbackRun(
	void *pcmObject,
	PCMSampleRange sampleRange,
	AudioBufferList *bufferList);

////////////////////////////////////////////////////////////////////////////////

typedef	OSStatus (^RMSCallbackBlock)
		(PCMSampleRange sampleRange, AudioBufferList *audio);



@interface RMSCallback : NSObject
{
	RMSCallbackInfo mCallbackInfo;
	RMSCallbackBlock mCallbackBlock;
}

+ (instancetype) instanceWithCallbackPtr:(void *)procPtr;
- (instancetype) initWithCallbackPtr:(void *)procPtr;
+ (instancetype) instanceWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm;
- (instancetype) initWithCallbackPtr:(void *)procPtr callbackPrm:(void *)procPrm;
+ (instancetype) instanceWithCallbackInfo:(RMSCallbackInfo)callbackInfo;
- (instancetype) initWithCallbackInfo:(RMSCallbackInfo)callbackInfo;

+ (const RMSCallbackProcPtr) callbackPtr;
- (const RMSCallbackInfo *) callbackInfoPtr;

+ (instancetype) instanceWithBlock:(RMSCallbackBlock)block;
- (instancetype) initWithBlock:(RMSCallbackBlock)block;

@end
////////////////////////////////////////////////////////////////////////////////




