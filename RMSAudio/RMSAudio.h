////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudio
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef RMSAudio_h
#define RMSAudio_h

#import "RMSCallback.h"
#import "RMSSource.h"
#import "RMSAudioUnit.h"
#import "RMSAudioUnitFilePlayer.h"
#import "RMSAudioUnitVarispeed.h"
#import "RMSAudioUnitPlatformIO.h"
#import "RMSInput.h"
#import "RMSOutput.h"

#import "RMSVolume.h"
#import "RMSAutoPan.h"
#import "RMSLowPassFilter.h"
#import "RMSMoogFilter.h"

#import "RMSMonitor.h"

#import "RMSMixer.h"
#import "RMSMixerSource.h"

#import "RMSSineWave.h"

#import "RMSTimer.h"
#import "RMSStereoView.h"

CF_ENUM(AudioFormatFlags)
{
	kAudioFormatFlagIsNativeEndian = kAudioFormatFlagsNativeEndian
};

static const AudioStreamBasicDescription RMSPreferredAudioFormat =
{
	.mSampleRate 		= 0.0,
	.mFormatID 			= kAudioFormatLinearPCM,
	.mFormatFlags 		=
		kAudioFormatFlagIsFloat | \
		kAudioFormatFlagIsNativeEndian | \
		kAudioFormatFlagIsPacked | \
		kAudioFormatFlagIsNonInterleaved,
	.mBytesPerPacket 	= sizeof(float),
	.mFramesPerPacket 	= 1,
	.mBytesPerFrame 	= sizeof(float),
	.mChannelsPerFrame 	= 2,
	.mBitsPerChannel 	= sizeof(float) * 8,
	.mReserved 			= 0
};

#endif /* RMSAudio_h */
