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

@property (nonatomic) RMSOutput *audioOutput;

@property (nonatomic) RMSVolume *volumeFilter;
@property (nonatomic, weak) IBOutlet NSSlider *gainControl;
@property (nonatomic, weak) IBOutlet NSSlider *volumeControl;
@property (nonatomic, weak) IBOutlet NSSlider *balanceControl;

@property (nonatomic) RMSAutoPan *autoPan;
@property (nonatomic, weak) IBOutlet NSButton *autoPanButton;

@property (nonatomic) RMSLowPassFilter *lowPassFilter;
@property (nonatomic, weak) IBOutlet NSTextField *cutOffLabel;
@property (nonatomic, weak) IBOutlet NSSlider *cutOffControl;
@property (nonatomic, weak) IBOutlet NSSlider *resonanceControl;

@property (nonatomic) RMSDelay *delayFilter;
@property (nonatomic, weak) IBOutlet NSTextField *delayTimeLabel;
@property (nonatomic, weak) IBOutlet NSSlider *delayTimeControl;
@property (nonatomic, weak) IBOutlet NSSlider *delayFeedBackControl;
@property (nonatomic, weak) IBOutlet NSSlider *delayMixControl;


@property (nonatomic) RMSMonitor *levelsMonitor;
@property (nonatomic, weak) IBOutlet RMSStereoView *stereoView;

@end



@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
	
	
	self.audioOutput = [RMSOutput defaultOutput];
	self.audioOutput.source = [RMSInput defaultInput];
	
	self.volumeFilter = [RMSVolume new];
	self.audioOutput.filter = self.volumeFilter;
	
	self.levelsMonitor = [RMSMonitor new];
	self.audioOutput.monitor = self.levelsMonitor;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	RMSTimer is a global timer to allow updates of UI elements with reasonable 
	visual continuity (about 24x per second). 
	By implementing globalRMSTimerDidFire an object can add itself as observer
	and receive updates. It can be used to update level metering or controls.
*/
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	The volume filter automatically does the right interpolation of values 
	over buffer duration. For the speed of user control, this is likely 
	sufficient in most cases.
	It can be used to control any source consistently, which means that the code
	for a generator source can concentrate on generating sound, and not have 
	to worry about correct volume control. 
	Simply attach an instance of RMSVolume as filter to the source.
*/
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

////////////////////////////////////////////////////////////////////////////////
/*
	RMSAutoPan is a kind of PID controller for keeping balance centered. 
	Here we deactivate the balanceslider and add the AutoPan filter.
	The correction balance value is reflected by the balanceslider in the
	globalRMSTimerDidFire call. 
	
	Switching back is simply a matter of removing the filter. Removing a filter 
	is guarded for existence in the audiothread, so we can set it to nil safely.
*/
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

////////////////////////////////////////////////////////////////////////////////
#pragma mark
#pragma mark Low Pass
////////////////////////////////////////////////////////////////////////////////

- (IBAction) didSelectLowPass:(NSButton *)button
{
	if (self.lowPassFilter == nil)
	{
//		self.lowPassFilter = [RMSLowPassFilter new];
		self.lowPassFilter = [RMSMoogFilter new];
		[self.lowPassFilter setCutOff:self.cutOffControl.floatValue];
		[self.lowPassFilter setResonance:self.resonanceControl.floatValue];
		[self.audioOutput addFilter:self.lowPassFilter];
	}
	else
	{
		[self.audioOutput removeFilter:self.lowPassFilter];
		self.lowPassFilter = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didAdjustCutOff:(NSSlider *)sender
{
	self.lowPassFilter.cutOff = sender.floatValue;
	
	float F = self.lowPassFilter.frequency;
	self.cutOffLabel.stringValue = [NSString stringWithFormat:@"Cut off: %.1f", F];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didAdjustResonance:(NSSlider *)sender
{
	self.lowPassFilter.resonance = sender.floatValue;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
#pragma mark Delay
////////////////////////////////////////////////////////////////////////////////

- (IBAction) didSelectDelay:(NSButton *)button
{
	if (self.delayFilter == nil)
	{
		self.delayFilter = [RMSDelay new];
		[self.delayFilter setDelayTime:self.delayTimeControl.floatValue];
		[self.delayFilter setFeedBack:self.delayFeedBackControl.floatValue];
		[self.delayFilter setMix:self.delayMixControl.floatValue];

		[self.audioOutput addFilter:self.delayFilter];
	}
	else
	{
		[self.audioOutput removeFilter:self.delayFilter];
		self.delayFilter = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didAdjustDelayTime:(NSSlider *)sender
{
	self.delayFilter.delayTime = sender.floatValue;
	
	float T = self.delayFilter.delayTime;
	self.delayTimeLabel.stringValue = [NSString stringWithFormat:@"Time: %.4f", T];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didAdjustDelayFeedBack:(NSSlider *)sender
{
	self.delayFilter.feedBack = sender.floatValue;	
}

- (IBAction) didAjdustDelayMix:(NSSlider *)sender
{
	self.delayFilter.mix = sender.floatValue;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
#pragma mark Input Source Selection
////////////////////////////////////////////////////////////////////////////////
/*
	A pure sine wave for RMS power testing
*/
- (IBAction) didSelectTestSignal:(NSButton *)button
{
	// Protect our ears
	self.volumeFilter.gain = 0.0;
	self.volumeFilter.volume = 0.1;
	self.gainControl.floatValue = 0.0;
	self.volumeControl.floatValue = 0.1;
	[NSThread sleepForTimeInterval:0.05];
	
	// Start testsignal
//	self.audioOutput.source = [RMSTestSignal sineWaveWithFrequency:441.0];
	self.audioOutput.source = [RMSTestSignal blockWaveWithFrequency:441.0];
//	self.audioOutput.source = [RMSTestSignal triangleWaveWithFrequency:441.0];
//	self.audioOutput.source = [RMSTestSignal sawToothWaveWithFrequency:441.0];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didSelectMicButton:(NSButton *)button
{
	RMSSource *source = [RMSInput defaultInput];
	
	/* 
		RMSInput is initialized with the device sampleRate, 
		which on iOS is simply the AVAudioSession sampleRate. 
		
		On OSX however, the samplerate may be different from the output, 
		for this case it has a simple linear interpolating ringbuffer build-in.

		If a more sophisticated algorithm is desired, the Varispeed audiounit
		can be used instead.

		// Attach Varispeed unit in between input and output
		if (source.sampleRate != self.audioOutput.sampleRate)
		{ source = [RMSAudioUnitVarispeed instanceWithSource:source]; }
	*/
	
	// Attaching automatically sets the output sampleRate for source
	self.audioOutput.source = source;
}

////////////////////////////////////////////////////////////////////////////////
/*
	Select a music file and play it. 
	
	Note that the RMSAudioUnitVarispeed is automatically attached if necessary.
	
	sampleRate always refers to the output samplerate of an RMSSource.
	Where appropriate, the input sampleRate should be set by a specific method, 
	unless the sampleRate is implicated.
*/

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
	if (source != nil)
	{
		if (source.sampleRate != self.audioOutput.sampleRate)
		{
			source = [RMSAudioUnitVarispeed instanceWithSource:source];
		}
	}
	
	// Attaching automatically sets the output sampleRate for source
	[self.audioOutput setSource:source];
}


@end
