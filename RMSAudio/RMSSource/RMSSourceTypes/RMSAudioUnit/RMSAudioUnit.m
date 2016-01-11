////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUnit
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSAudioUnit.h"
#import "RMSAudio.h"
#import "PCMAudioUtilities.h"


@interface RMSAudioUnit ()
{
	BOOL mAudioUnitIsInitialized;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSAudioUnit
////////////////////////////////////////////////////////////////////////////////
/*
	The RMSCallback for an RMSAudioUnit defaults to calling AudioUnitRender
*/
static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSAudioUnit *rmsSource = \
	(__bridge __unsafe_unretained RMSAudioUnit *)inRefCon;
	
	return AudioUnitRender(rmsSource->mAudioUnit,
	actionFlags, timeStamp, busNumber, frameCount, bufferList);
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	Following implementation allows all subclasses to use [super init]
	for initialization by overwriting the class componentdescription, or
	alternatively default to an instance of AUHAL.
	
	We use a class global componentDescription since an instance->componentDescription 
	should generally reflect the current internal state of an object.
	
	initWithDescription: ensures that we are responsible for creating the audioUnit, 
	and hence also should dispose of it properly.

	Technically we might want to include a default initializer that supplies the audioUnit,
	e.g. initWithAudioUnit: since RMSAudioUnit merely is an audioUnit controller object, 
	but that would make it less clear who's responsible for disposing the audioUnit.
*/

#if TARGET_OS_DESKTOP
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_HALOutput
#else
#define kAudioUnitSubType_PlatformIO kAudioUnitSubType_RemoteIO
#endif


+ (AudioComponentDescription) componentDescription
{
	return
	(AudioComponentDescription) {
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_PlatformIO,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0 };
}

- (instancetype) init
{ return [self initWithDescription:[[self class] componentDescription]]; }

////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_DESKTOP

- (instancetype) initWithAUHAL
{
	return [self initWithDescription:
	(AudioComponentDescription){
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_HALOutput,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0
	}];
}

#else

- (instancetype) initWithAURemoteIO
{
	return [self initWithDescription:
	(AudioComponentDescription){
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_RemoteIO,
		.componentManufacturer = kAudioUnitManufacturer_Apple,
		.componentFlags = 0,
		.componentFlagsMask = 0
	}];
}

#endif

////////////////////////////////////////////////////////////////////////////////
// Default initializer

+ (instancetype) instanceWithDescription:(AudioComponentDescription)desc
{ return [[self alloc] initWithDescription:desc]; }

- (instancetype) initWithDescription:(AudioComponentDescription)desc
{
	self = [super init];
	if (self != nil)
	{
		mAudioUnit = NewAudioUnitWithDescription(desc);
		if (mAudioUnit == nil) return nil;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	if (mAudioUnit != nil)
	{ AudioComponentInstanceDispose(mAudioUnit); }
	mAudioUnit = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (OSStatus) initializeAudioUnit
{
	OSStatus result = AudioUnitInitialize(mAudioUnit);
	if (result == noErr)
	{ mAudioUnitIsInitialized = YES; }
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) uninitializeAudioUnit
{
	OSStatus result = AudioUnitUninitialize(mAudioUnit);
	if (result == noErr)
	{ mAudioUnitIsInitialized = NO; }
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSampleRate:(Float64)sampleRate
{
	[super setSampleRate:sampleRate];

	AudioStreamBasicDescription streamFormat;
	OSStatus result = [self getResultFormat:&streamFormat];
	if (result == noErr)
	{
		// Check for actual change of sampleRate
		if (streamFormat.mSampleRate != sampleRate)
		{
			streamFormat.mSampleRate = sampleRate;
			result = [self setResultFormat:&streamFormat];
			// kAudioUnitErr_PropertyNotWritable
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) getSourceFormat:(AudioStreamBasicDescription *)streamInfoPtr
{
	OSStatus result = PCMAudioUnitGetOutputSourceFormat(mAudioUnit, streamInfoPtr);
	if (result != noErr)
	{ NSLog(@"getSourceFormat returned %d", result); }

	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) setSourceFormat:(const AudioStreamBasicDescription *)streamInfoPtr
{
	if (mAudioUnitIsInitialized)
	AudioUnitUninitialize(mAudioUnit);
	
	OSStatus result = PCMAudioUnitSetOutputSourceFormat(mAudioUnit, streamInfoPtr);
	if (result != noErr)
	{ NSLog(@"setSourceFormat returned %d", result); }

	if (mAudioUnitIsInitialized)
	AudioUnitInitialize(mAudioUnit);

	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) getResultFormat:(AudioStreamBasicDescription *)streamInfoPtr
{
	OSStatus result = PCMAudioUnitGetOutputResultFormat(mAudioUnit, streamInfoPtr);
	if (result != noErr)
	{ NSLog(@"getResultFormat returned %d", result); }
	
	return result;
}

- (OSStatus) setResultFormat:(const AudioStreamBasicDescription *)streamInfoPtr
{
	if (mAudioUnitIsInitialized)
	AudioUnitUninitialize(mAudioUnit);

	OSStatus result = PCMAudioUnitSetOutputResultFormat(mAudioUnit, streamInfoPtr);
	if (result != noErr)
	{ NSLog(@"setResultFormat returned %d", result); }

	if (mAudioUnitIsInitialized)
	AudioUnitInitialize(mAudioUnit);

	return result;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////







