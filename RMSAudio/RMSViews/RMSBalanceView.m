////////////////////////////////////////////////////////////////////////////////
/*
	RMSBalanceView.m
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSBalanceView.h"
#import "RMSIndexView.h"


@interface RMSBalanceView ()
{
	NSView *mIndicator;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSBalanceView
////////////////////////////////////////////////////////////////////////////////

- (void) updateLevels
{
	[super updateLevels];
	[self updateBalance];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateBalance
{
	double L = self.enginePtrL ? self.enginePtrL->mBal : 0.0;
	double R = self.enginePtrR ? self.enginePtrR->mBal : 0.0;

	[self setBalance:R-L];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setBalance:(double)balance
{
	// Compute offset for display
	double m = RMS2DISPLAY(fabs(balance));
	if (balance < 0.0) m = -m;
	
	NSRect frame = self.bounds;
	frame.origin.x += 0.5*frame.size.width;
	frame.origin.x += 0.5*frame.size.width * m;
	frame.origin.x -= 1.0;
	frame.size.width = 2.0;
	self.balanceIndicator.frame = frame;
}

////////////////////////////////////////////////////////////////////////////////

- (NSRect) frameForResultViewL
{
	// Compute left side of bounds
	NSRect frame = self.bounds;
	frame.size.width *= 0.5;
	frame.size.width -= 1.0;

	return frame;
}

////////////////////////////////////////////////////////////////////////////////

- (NSRect) frameForResultViewR
{
	// Compute right side of bounds
	NSRect frame = self.bounds;
	frame.size.width *= 0.5;
	frame.size.width -= 1.0;
	frame.origin.x += frame.size.width+2.0;

	return frame;
}

////////////////////////////////////////////////////////////////////////////////

// Overwrite to set drawing direction
- (RMSResultView *) resultViewL
{
	RMSResultView *view = [super resultViewL];
	view.direction = eRMSViewDirectionW;
	return view;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
#pragma mark Drawing
////////////////////////////////////////////////////////////////////////////////

- (void) drawRect:(NSRect)rect
{
	[[NSColor blackColor] set];
	NSRectFill(rect);
}

////////////////////////////////////////////////////////////////////////////////

- (NSView *) balanceIndicator
{
	if (mIndicator == nil)
	{
		// Create 2 point wide view
		NSRect frame = self.bounds;
		frame.origin.x += 0.5*frame.size.width;
		frame.origin.x -= 1.0;
		frame.size.width = 2.0;
		
		// Abuse background layer for coloring (OSX)
		mIndicator = [[NSView alloc] initWithFrame:frame];
		
		#if !TARGET_OS_IOS
		mIndicator.wantsLayer = YES;
		#endif
		mIndicator.layer.backgroundColor = [NSColor redColor].CGColor;

		// Add as subview
		[self addSubview:mIndicator];
	}
	
	return mIndicator;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
