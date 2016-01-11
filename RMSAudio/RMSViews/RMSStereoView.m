////////////////////////////////////////////////////////////////////////////////
/*
	RMSStereoView.m
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSStereoView.h"


@interface RMSStereoView ()
{
	RMSResultView *mViewL;
	RMSResultView *mViewR;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSStereoView
////////////////////////////////////////////////////////////////////////////////

- (NSRect) frameForResultViewL
{
	NSRect frame = self.bounds;
	frame.origin.y += frame.size.height;
	frame.size.height = floor(0.5*frame.size.height);
	frame.origin.y -= frame.size.height;
	return frame;
}

////////////////////////////////////////////////////////////////////////////////

- (NSRect) frameForResultViewR
{
	NSRect frame = self.bounds;
	frame.size.height = floor(0.5*frame.size.height);
	return frame;
}

////////////////////////////////////////////////////////////////////////////////

- (RMSResultView *) resultViewL
{
	if (mViewL == nil)
	{
		// Compute top half of frame
		NSRect frame = [self frameForResultViewL];
		
		// Create levels view with default drawing direction
		mViewL = [[RMSResultView alloc] initWithFrame:frame];
		
		// Add as subview
		[self addSubview:mViewL];
	}
	
	return mViewL;
}

////////////////////////////////////////////////////////////////////////////////

- (RMSResultView *) resultViewR
{
	if (mViewR == nil)
	{
		// Compute bottom half of frame
		NSRect frame = [self frameForResultViewR];
		
		// Create levels view with default drawing direction
		mViewR = [[RMSResultView alloc] initWithFrame:frame];
		
		// Add as subview
		[self addSubview:mViewR];
	}
	
	return mViewR;
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateLevels
{
	[self setResultL:RMSEngineFetchResult(self.enginePtrL)];
	[self setResultR:RMSEngineFetchResult(self.enginePtrR)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setResultL:(rmsresult_t)levels
{ [self.resultViewL setLevels:levels]; }

- (void) setResultR:(rmsresult_t)levels
{ [self.resultViewR setLevels:levels]; }

////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(NSRect)rect
{
	[[NSColor blackColor] set];
	NSRectFill(rect);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
