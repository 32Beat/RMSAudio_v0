////////////////////////////////////////////////////////////////////////////////
/*
	RMSStereoView.h
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSResultView.h"

@interface RMSStereoView : NSView

@property (nonatomic, assign) const rmsengine_t *enginePtrL;
@property (nonatomic, assign) const rmsengine_t *enginePtrR;

- (NSRect) frameForResultViewL;
- (NSRect) frameForResultViewR;

- (RMSResultView *) resultViewL;
- (RMSResultView *) resultViewR;

// Copy rmsresults from engine to views
- (void) updateLevels;
- (void) setResultL:(rmsresult_t)levels;
- (void) setResultR:(rmsresult_t)levels;

@end
