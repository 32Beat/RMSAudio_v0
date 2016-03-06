////////////////////////////////////////////////////////////////////////////////
/*
	RMSOutput
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSOutput.h"
#import "RMSAudio.h"
#import "PCMAudioUtilities.h"

#import <AVFoundation/AVFoundation.h>
#import <mach/mach_time.h>


@interface RMSOutput ()
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSOutput
////////////////////////////////////////////////////////////////////////////////

#define RMS_REPORT_TIME 2

#if RMS_REPORT_TIME

static OSStatus notifyCallback(
	void *							inRefCon,
	AudioUnitRenderActionFlags *	ioActionFlags,
	const AudioTimeStamp *			inTimeStamp,
	UInt32							inBusNumber,
	UInt32							inNumberFrames,
	AudioBufferList * __nullable	ioData)
{
	static UInt64 startTime = 0;
	static UInt64 finishTime = 0;
	
	if (*ioActionFlags & kAudioUnitRenderAction_PreRender)
	{
		startTime = mach_absolute_time();
	}
	else
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender)
	{
		finishTime = mach_absolute_time();
		
		double renderTime = RMSHostTimeToSeconds(finishTime - startTime);
		
		// Compute short term average time
		static double avgTime = 0;
		avgTime += 0.1 * (renderTime - avgTime);
		
		// Compute maximum time since last report
		static double maxTime = 0;
		if (maxTime < renderTime)
		{ maxTime = renderTime; }
		
		// Check report frequency
		static double lastTime = 0;
		double time = RMSCurrentHostTimeInSeconds();
		if (lastTime + RMS_REPORT_TIME <= time)
		{
			lastTime = time;
			double reportTime1 = avgTime;
			double reportTime2 = maxTime;
			dispatch_async(dispatch_get_main_queue(), \
			^{
				NSLog(@"Render time avg = %lfs)", reportTime1);
				NSLog(@"Render time max = %lfs)", reportTime2);
			});
			
			maxTime = 0;
		}
	}
	
	return noErr;
}

#endif

////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void *							refCon,
	AudioUnitRenderActionFlags *	actionFlagsPtr,
	const AudioTimeStamp *			timeStampPtr,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList * __nullable	bufferListPtr)
{
	__unsafe_unretained RMSOutput *rmsObject =
	(__bridge __unsafe_unretained RMSOutput *)refCon;
	
	AudioBufferList_ClearFrames(bufferListPtr, frameCount);

	OSStatus result = noErr;

	Float64 sampleRate = 0.0;
	result = PCMAudioUnitGetOutputScopeSampleRateAtIndex(rmsObject->mAudioUnit, 0, &sampleRate);
	if ((sampleRate != 0.0) && (sampleRate != rmsObject->mSampleRate))
	{
		/*
			A device samplerate change is typically destructive, 
			produce silence + error until the management thread 
			has had a chance to incorporate the change.
		*/
		return paramErr;
	}
	
	if (rmsObject->mSource != nil)
		result = RunRMSSource((__bridge void *)rmsObject->mSource,
		actionFlagsPtr, timeStampPtr, busNumber, frameCount, bufferListPtr);
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

+ (AURenderCallback) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_DESKTOP

+ (instancetype) defaultOutput
{
	return [[self alloc] initWithDeviceID:0];
}

////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithDeviceID:(AudioDeviceID)deviceID
{
	self = [super init];
	if (self != nil)
	{
		OSStatus result = noErr;
		
		result = [self prepareAudioUnit];
		if (result != noErr) return nil;

		result = [self attachDevice:deviceID];
		if (result != noErr) return nil;

		result = [self initializeSampleRates];
		if (result != noErr) return nil;
		
		result = [self prepareBuffers];
		if (result != noErr) return nil;
		
		[self startRunning];
	}
	
	return self;
}


- (OSStatus) attachDevice:(AudioDeviceID)deviceID
{
	OSStatus result = noErr;
	
	if (deviceID != 0)
	{
		result = AudioUnitAttachDevice(mAudioUnit, deviceID);
		if (result != noErr) return result;
	}
	
	return result;
}

#endif

////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_IPHONE

+ (instancetype) defaultOutput
{
	return [[self alloc] init];
}

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{
	self = [super init];
	if (self != nil)
	{
		OSStatus result = noErr;
		
		result = [self prepareAudioUnit];
		if (result != noErr) return nil;

		result = [self initializeSampleRates];
		if (result != noErr) return nil;
		
		result = [self prepareBuffers];
		if (result != noErr) return nil;
		
		[self startRunning];
	}
	
	return self;
}

#endif

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self stopRunning];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (OSStatus) prepareAudioUnit
{
	OSStatus result = noErr;

#if RMS_REPORT_TIME
	AudioUnitAddRenderNotify(mAudioUnit, notifyCallback, nil);
#endif
/*
	Use RunRMSSource as the render callback, so RMSOutput behaves 
	exactly symmetrical in stand-alone mode, or as part of a rendertree.
*/
	result = AudioUnitSetRenderCallback(mAudioUnit, RunRMSSource, (__bridge void *)self);
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) initializeSampleRates
{
	OSStatus result = noErr;

	// Get outputScope format
	AudioStreamBasicDescription resultFormat;
	[self getResultFormat:&resultFormat];

	mSampleRate = resultFormat.mSampleRate;
	
	// Set inputScope to our preferred format with the outputScope sampleRate
	AudioStreamBasicDescription streamFormat = RMSPreferredAudioFormat;
	streamFormat.mSampleRate = resultFormat.mSampleRate;
	[self setSourceFormat:&streamFormat];
	
#if TARGET_OS_IPHONE

	// On iOS the audiounit sampleRate will be 0 on both scopes,
	// need to copy it from the AVAudioSession
	mSampleRate = [[AVAudioSession sharedInstance] sampleRate];

#endif
	
	// Set most reasonable guestimate, if necessary
	if (mSampleRate == 0)
	{ mSampleRate = 44100.0; }
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) prepareBuffers
{
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

- (OSStatus) prepareBuffersWithMaxFrameCount:(UInt32)frameCount
{
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////
/*
	Samplerate is only propagated to filters and monitors, as these operate on 
	output samples, while a source might specifically need to produce samples 
	at a different rate, like in the Varispeed case.
	For correct reproduction, the output unit needs to receive correctly rated 
	samples directly from its source.
*/

- (void) setSource:(RMSSource *)source
{
	[source setSampleRate:self.sampleRate];
	[super setSource:source];
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





