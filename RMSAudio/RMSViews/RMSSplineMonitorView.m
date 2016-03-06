//
//  RMSSplineMonitorView.m
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSplineMonitorView.h"

@interface RMSSplineMonitorView ()
{
	double mE[kRMSSplineMonitorCount];
	double mMinValue;
	
	NSImageRep *mImageRep;
}
@end

@implementation RMSSplineMonitorView

- (void) setErrorData:(double *)resultPtr minValue:(double)minValue
{
	memcpy(mE, resultPtr, kRMSSplineMonitorCount * sizeof(double));
	mMinValue = minValue;
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
	NSRect B = self.bounds;
	
	[[NSColor whiteColor] set];
	NSRectFill(B);
	
	[[NSColor darkGrayColor] set];

	NSBezierPath *path = [NSBezierPath new];
	
	float x = B.origin.x;
	float xstep = B.size.width / (kRMSSplineMonitorCount-1);
	[path moveToPoint:(NSPoint){ x, mE[0]*B.size.height }];
	for (long n=1; n!=kRMSSplineMonitorCount; n++)
	{
		x += xstep;
		[path lineToPoint:(NSPoint){ x, mE[n]*B.size.height }];
	}
	[path stroke];

	[[NSColor redColor] set];
	[path removeAllPoints];
	float X1 = NSMinX(B)+B.size.width * mMinValue;
	float X2 = X1;
	float Y1 = NSMinY(B);
	float Y2 = NSMaxY(B);
	[path moveToPoint:(NSPoint){ X1, Y1 }];
	[path lineToPoint:(NSPoint){ X2, Y2 }];
	[path stroke];
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

@end
