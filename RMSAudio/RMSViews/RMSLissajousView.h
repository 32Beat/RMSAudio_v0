//
//  RMSLissajousView.h
//  RMSAudioApp
//
//  Created by 32BT on 07/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitor.h"


#define kRMSLissajousCount 	512


@interface RMSLissajousView : NSView

@property (nonatomic, weak) RMSSampleMonitor *sampleMonitor;

- (void) triggerUpdate;

@end
