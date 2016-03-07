////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

#define kRMSSplineMonitorCount 	32


@interface RMSSplineMonitor : RMSSource
- (void) getErrorData:(double *)resultPtr minValue:(double *)minValuePtr;

//- (NSBitmapImageRep *) imageRepWithGain:(UInt32)a;

@end
