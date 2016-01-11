////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudio
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef RMSAudio_h
#define RMSAudio_h

#include "RMSCallback.h"
#include "RMSSource.h"
#include "RMSAudioUnit.h"
#include "RMSAudioUnitFilePlayer.h"
#include "RMSAudioUnitVarispeed.h"
#include "RMSAudioUnitPlatformIO.h"
#include "RMSInput.h"
#include "RMSOutput.h"

#include "RMSVolume.h"
#include "RMSAutoPan.h"

#include "RMSMonitor.h"

#include "RMSMixer.h"
#include "RMSMixerSource.h"

#include "RMSTimer.h"
#include "RMSStereoView.h"

CF_ENUM(AudioFormatFlags)
{
	kAudioFormatFlagIsNativeEndian = kAudioFormatFlagsNativeEndian
};

static const AudioStreamBasicDescription RMSPreferredAudioFormat =
{
	.mSampleRate 		= 44100.0,
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
