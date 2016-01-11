////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUnitFilePlayer
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSAudioUnit.h"

@interface RMSAudioUnitFilePlayer : RMSAudioUnit
{
	AudioFileID mFileID;
	AudioStreamBasicDescription mFileFormat;
}

+ (instancetype) instanceWithURL:(NSURL *)fileURL;

@end
