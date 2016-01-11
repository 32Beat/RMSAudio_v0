//
//  MainViewController.m
//  RMSAudioApp
//
//  Created by 32BT on 10/01/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "MainViewController.h"

#import "RMSAudio.h"

@interface MainViewController () <RMSTimerProtocol>
@property (nonatomic) RMSInput *audioInput;
@property (nonatomic) RMSOutput *audioOutput;
@property (nonatomic) RMSMonitor *levelsMonitor;

@property (nonatomic, weak) IBOutlet RMSStereoView *stereoView;
@end



@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
	
	
	self.audioOutput = [RMSOutput defaultOutput];
	
	self.audioInput = [RMSInput defaultInput];
	self.audioOutput.source = self.audioInput;
	
	self.levelsMonitor = [RMSMonitor new];
	self.audioOutput.monitor = self.levelsMonitor;
}

- (void) viewWillAppear
{
	[super viewWillAppear];
	[RMSTimer addRMSTimerObserver:self];
}

- (void) viewWillDisappear
{
	[RMSTimer removeRMSTimerObserver:self];
	[super viewWillDisappear];
}


- (void) globalRMSTimerDidFire
{
	rmsresult_t resultL = self.levelsMonitor.resultLevelsL;
	rmsresult_t resultR = self.levelsMonitor.resultLevelsR;
	self.stereoView.resultL = resultL;
	self.stereoView.resultR = resultR;
}

- (IBAction) didSelectButton:(NSButton *)button
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result)
	{
		[panel orderOut:self];

		if (result != 0)
		{
			NSURL *url = [panel URLs][0];
			[self startFileWithURL:url];
		}
	}];
}


- (void) startFileWithURL:(NSURL *)url
{
	RMSSource *source = [RMSAudioUnitFilePlayer instanceWithURL:url];

	if (source.sampleRate != self.audioOutput.sampleRate)
	source = [RMSAudioUnitVarispeed instanceWithSource:source];

	[self.audioOutput setSource:source];
}


@end
