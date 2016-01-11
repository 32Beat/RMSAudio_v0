////////////////////////////////////////////////////////////////////////////////
/*
	RMSBalanceView.h
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSStereoView.h"

@interface RMSBalanceView : RMSStereoView

- (NSView *) balanceIndicator;

- (void) updateBalance;
- (void) setBalance:(double)balance;

@end
