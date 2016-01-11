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

@property (nonatomic) RMSVolume *volumeFilter;
@property (nonatomic, weak) IBOutlet NSSlider *gainControl;
@property (nonatomic, weak) IBOutlet NSSlider *volumeControl;
@property (nonatomic, weak) IBOutlet NSSlider *balanceControl;

@property (nonatomic) RMSAutoPan *autoPan;
@property (nonatomic, weak) IBOutlet NSButton *autoPanButton;

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
	
	self.volumeFilter = [RMSVolume new];
	self.audioOutput.filter = self.volumeFilter;
	
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
	
	if (self.autoPan != nil)
	{ self.balanceControl.floatValue = self.autoPan.correctionBalance; }
}



- (IBAction) didAdjustGainControl:(NSSlider *)slider
{
	float V = [slider floatValue];
	self.volumeFilter.gain = V;
}

- (IBAction) didAdjustVolumeControl:(NSSlider *)slider
{
	float V = [slider floatValue];
	self.volumeFilter.volume = V;
}

- (IBAction) didAdjustBalanceControl:(NSSlider *)slider
{
	float V = [slider floatValue];
	self.volumeFilter.balance = V;
}

- (IBAction) didSelectAutoPan:(NSButton *)button
{
	if (self.autoPan == nil)
	{
		self.balanceControl.enabled = NO;
		self.autoPan = [RMSAutoPan new];
		[self.audioOutput addFilter:self.autoPan];
	}
	else
	{
		[self.audioOutput removeFilter:self.autoPan];
		self.autoPan = nil;
		self.balanceControl.enabled = YES;
		
		self.balanceControl.floatValue = self.volumeFilter.balance;
	}
}

- (IBAction) didSelectTestSignal:(NSButton *)button
{
	// Protect our ears
	self.volumeFilter.gain = 0.0;
	self.volumeFilter.volume = 0.1;
	self.gainControl.floatValue = 0.0;
	self.volumeControl.floatValue = 0.1;
	
	// Start sinewave
	self.audioOutput.source = [RMSSineWave instanceWithFrequency:440.0];
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
