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
	{
		[mImageArray insertObject:imageRep atIndex:0];
		[self updateArrayForSize:self.bounds.size];
	}
	
	[self setNeedsDisplay:YES];
}


- (void) updateArrayForSize:(NSSize)size
{
	NSInteger n = 0;
	CGFloat H = 0.0;
	
	while ((n < mImageArray.count) && (H < size.height))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		H += imageRep.size.height;
		n += 1;
	}

	while (mImageArray.count > n)
	{ [mImageArray removeLastObject]; }
}


// Q&D moving spectrum
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	[[NSColor blackColor] set];
	NSRectFill(self.bounds);
	
	NSRect dstR = self.bounds;
	CGFloat maxY = NSMaxY(dstR);
	CGFloat minY = NSMinY(dstR);
	dstR.origin.y = maxY;
	
	UInt32 n = 0;

	while ((n < mImageArray.count)&&(dstR.origin.y > minY))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		
		dstR.size.height = imageRep.size.height;
		dstR.origin.y -= dstR.size.height;
		
		[imageRep drawInRect:dstR];

		n += 1;
	}
}

@end





