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
	size_t mCount;
	float mL[kRMSLissajousCount];
	float mR[kRMSLissajousCount];
	
	double mFilterL;
	double mFilterR;
}
@end



////////////////////////////////////////////////////////////////////////////////
@implementation RMSLissajousView
////////////////////////////////////////////////////////////////////////////////

- (void) setDuration:(float)value
{
	if (value > 1.0) value = 1.0;
	[self setCount:value * kRMSLissajousCount];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCount:(size_t)count
{
	if (count == 0)
	{ count = 1; }
	
	if (mCount != count)
	{
		mCount = count;
		[self triggerUpdate];
	}
}

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	[self adjustOrigin];

    // Drawing code here.
	[[NSColor darkGrayColor] set];
	NSRectFill(self.bounds);
	
	[[NSColor blackColor] set];
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:(NSPoint){ 0.0, NSMinY(self.bounds) }];
	[path lineToPoint:(NSPoint){ 0.0, NSMaxY(self.bounds) }];
	[path moveToPoint:(NSPoint){ NSMinX(self.bounds), 0.0 }];
	[path lineToPoint:(NSPoint){ NSMaxX(self.bounds), 0.0 }];
	[self drawPath:path];
	
	
	[[NSColor whiteColor] set];
	path = [NSBezierPath new];
	
	if (mCount == 0)
	{ mCount = 1; }
	
	
	for (int n=0; n!=mCount; n++)
	{
		mFilterL += 0.01 * (mL[n] - mFilterL);
		mFilterR += 0.01 * (mR[n] - mFilterR);
		
		double L = mFilterL;
		double R = mFilterR;
		double D = pow(R*R+L*L, 0.5);
		
		D = D != 0.0 ? sqrt(D) / D : 1.0;
		
		D *= (const double)(sqrt(2.0)/2.0);
		
		[path moveToPoint:CGPointZero];
		[path lineToPoint:(NSPoint){ D*(R-L), D*(R+L) }];
	}
	
	[self drawPath:path];
	
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////

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
	CGFloat S = 0.5 * MIN(B.size.width, B.size.height);
	
	NSAffineTransform *T = [NSAffineTransform transform];
//	[T translateXBy:B.size.width/2.0 yBy:B.size.height/2.0];
	[T scaleBy:S];
//	[T rotateByDegrees:45.0];
	
	[[T transformBezierPath:path] stroke];
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////







