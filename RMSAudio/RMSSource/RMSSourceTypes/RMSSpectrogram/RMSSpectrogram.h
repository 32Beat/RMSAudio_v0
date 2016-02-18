////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSClip.h"


@interface RMSSpectrogram : RMSSource

- (instancetype) initWithLength:(size_t)N;

- (NSBitmapImageRep *) imageRep;
- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index;
- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index sensitivity:(UInt32)s;
- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range;
- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range sensitivity:(UInt32)s;

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image;

@end
