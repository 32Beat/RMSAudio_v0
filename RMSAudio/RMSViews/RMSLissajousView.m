//
//  RMSLissajousView.m
//  RMSAudioApp
//
//  Created by 32BT on 07/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSLissajousView.h"


@interface RMSLissajousView ()
{
	float mL[kRMSLissajousCount];
	float mR[kRMSLissajousCount];
}
@end



@implementation RMSLissajousView

- (void) triggerUpdate
{
	RMSSampleMonitor *sampleMonitor = self.sampleMonitor;
	if (sampleMonitor != nil)
	{
		float *ptr[2] = { mL, mR };
		[sampleMonitor getSamples:ptr count:kRMSLissajousCount];
		[self setNeedsDisplay:YES];
	}
}


- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	[self adjustOrigin];
	
    // Drawing code here.
	[[NSColor blackColor] set];
	NSRectFill(self.bounds);
	
	[[NSColor whiteColor] set];
	NSBezierPath *path = [NSBezierPath new];
	
	
	
	[path moveToPoint:(NSPoint){ mR[0], mL[0] }];
	for (int n=1; n!=kRMSLissajousCount; n++)
	{
		[path lineToPoint:(NSPoint){ mR[n], mL[n] }];
	}
	
	[self drawPath:path];
	
}


- (void) adjustOrigin
{
	NSRect B = self.bounds;
	CGFloat x = 0.50 * B.size.width;
	CGFloat y = 0.50 * B.size.height;
	B.origin.x = -(floor(x)+0.5);
	B.origin.y = -(floor(y)+0.5);
	self.bounds = B;
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawPath:(NSBezierPath *)path
{
	NSRect B = self.bounds;
	
	NSAffineTransform *T = [NSAffineTransform transform];
	[T scaleXBy:B.size.width/2.0 yBy:B.size.height/2.0];
	
	[[T transformBezierPath:path] stroke];
}

////////////////////////////////////////////////////////////////////////////////

@end







