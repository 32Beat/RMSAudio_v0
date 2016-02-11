//
//  NSBitmapImageRepView.m
//  RMSAudioApp
//
//  Created by 32BT on 08/02/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "NSBitmapImageRepView.h"

@interface NSBitmapImageRepView ()
{
	NSMutableArray *mImageArray;
}
@end

@implementation NSBitmapImageRepView



- (void) appendImageRep:(NSImageRep *)imageRep
{
	if (mImageArray == nil)
	{ mImageArray = [NSMutableArray new]; }
	
	if (imageRep != nil)
	[mImageArray insertObject:imageRep atIndex:0];
	
	[self setNeedsDisplay:YES];
}


// Q&D moving spectrum
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	NSRect dstR = self.bounds;
//	dstR.origin.x = -1024;\
	dstR.size.width = 2048;
	dstR.origin.y += dstR.size.height;
	
	UInt32 n = 0;

	while ((dstR.origin.y > 0)&&(n < mImageArray.count))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		
		dstR.size.height = imageRep.size.height;
		dstR.origin.y -= dstR.size.height;
		
		[imageRep drawInRect:dstR];

		n += 1;
	}
	
	while (mImageArray.count > n)
	{ [mImageArray removeLastObject]; }
	
}

@end





