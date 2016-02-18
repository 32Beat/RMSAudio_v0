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
- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index gain:(UInt32)a;
- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range;
- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range gain:(UInt32)a;

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image;

@end
