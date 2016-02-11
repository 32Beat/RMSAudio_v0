////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSSpectrogram : RMSSource

- (NSBitmapImageRep *) imageRep;
- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index;
- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range;

@end
