////////////////////////////////////////////////////////////////////////////////
/*
	RMSAudioUtilities
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSAudioUtilities.h"
#import <mach/mach_time.h>

////////////////////////////////////////////////////////////////////////////////

static double g_rmsHostToSeconds = 1.0e-9;
static double g_rmsSecondsToHost = 1.0e+9;

////////////////////////////////////////////////////////////////////////////////

static void RMSHostTimeInit(void)
{
	static bool isInitialized = false;
	if (!isInitialized)
	{
		mach_timebase_info_data_t timeInfo;
		mach_timebase_info(&timeInfo);
		if (timeInfo.numer && timeInfo.denom)
		{
			g_rmsHostToSeconds = 1.0e-9 * timeInfo.numer / timeInfo.denom;
			g_rmsSecondsToHost = 1.0e+9 * timeInfo.denom / timeInfo.numer;
		}
		
		isInitialized = true;
	}
}

////////////////////////////////////////////////////////////////////////////////

double RMSCurrentHostTimeInSeconds(void)
{ return RMSHostTimeToSeconds(mach_absolute_time()); }

double RMSHostTimeToSeconds(double hostTime)
{
	RMSHostTimeInit();
	return hostTime * g_rmsHostToSeconds;
}

////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////




