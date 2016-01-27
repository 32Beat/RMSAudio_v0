////////////////////////////////////////////////////////////////////////////////
/*
	RMSMixerSourceController
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSMixerSourceController.h"
#import "RMSAudio.h"

@interface RMSMixerSourceController ()
{
	RMSMonitor *mMonitor;
}
@end

@implementation RMSMixerSourceController

+ (instancetype) instanceWithSource:(RMSMixerSource *)source
{ return [[self alloc] initWithSource:source]; }

- (instancetype) initWithSource:(RMSMixerSource *)source
{
	self = [super init];
	if (self != nil)
	{
		mSource = source;
		[mSource addMonitor:self.monitor];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (RMSMonitor *) monitor
{
	if (mMonitor == nil)
	{ mMonitor = [RMSMonitor new]; }
	
	return mMonitor;
}

////////////////////////////////////////////////////////////////////////////////

- (void) setSource:(RMSMixerSource *)source
{
	if (mSource != source)
	{
		[mSource removeMonitor:self.monitor];
		mSource = source;
		[mSource addMonitor:self.monitor];
		
		[self.volumeSlider setFloatValue:[mSource volume]];
		[self.balanceSlider setFloatValue:[mSource balance]];		
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
	
	[self.volumeSlider setFloatValue:[mSource volume]];
	[self.balanceSlider setFloatValue:[mSource balance]];
}

////////////////////////////////////////////////////////////////////////////////

- (void) viewWillAppear
{
	[super viewWillAppear];
	[RMSTimer addRMSTimerObserver:self];
}

////////////////////////////////////////////////////////////////////////////////

- (void) viewWillDisappear
{
	[RMSTimer removeRMSTimerObserver:self];
	[super viewWillDisappear];
}

////////////////////////////////////////////////////////////////////////////////
/*
	We are using the global timer for GUI updating as well, 
	since KVO just adds a lot of unnecessary overhead.
*/

- (void) globalRMSTimerDidFire
{
	[self updateButton];
	[self updateVolume];
	[self updateLevels];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (void) updateButton
{
/*
	// Enable button only if mute is settable
	BOOL enabledState =
	[_audioSource respondsToSelector:@selector(setChannelIsMuted:)];

	if (self.playButton.enabled != enabledState)
	{ self.playButton.enabled = enabledState; }
	
	// Fetch mute if available, default to ON
	NSInteger switchState =
	[_audioSource respondsToSelector:@selector(channelIsMuted)] ?
	_audioSource.channelIsMuted ? NSOffState : NSOnState : NSOnState;
	
	if (self.playButton.state != switchState)
	{ self.playButton.state = switchState; }
*/
}

- (void) updateLevels
{
	[self.stereoView setResultL:[self.monitor resultLevelsL]];
	[self.stereoView setResultR:[self.monitor resultLevelsR]];
}

- (void) updateVolume
{
/*
	// Enable slider only if volume is settable
	BOOL enabledState =
	[_audioSource respondsToSelector:@selector(setVolume:)];
	
	if (self.volumeSlider.enabled != enabledState)
	{ self.volumeSlider.enabled = enabledState; }
	
	// Fetch volume if available, default to 1.0
	float volume = [_audioSource respondsToSelector:@selector(volume)] ?
	_audioSource.volume : 1.0;
	
	if (self.volumeSlider.floatValue != volume)
	{ self.volumeSlider.floatValue = volume; }
*/
}

////////////////////////////////////////////////////////////////////////////////

- (void) setButtonTitle:(NSString *)str
{ self.playButton.title = str; }

- (IBAction) didAdjustButton:(NSButton *)button
{
/*
	if ([_audioSource respondsToSelector:@selector(setChannelIsMuted:)])
	[(id)_audioSource setChannelIsMuted:(button.state == NSOffState)];
*/
}

- (IBAction) didAdjustSlider:(NSSlider *)slider
{
	if ([mSource respondsToSelector:@selector(setVolume:)])
	[(id)mSource setVolume:slider.floatValue];
}

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
