//
//  RMSKaraokeViewController.m
//  RMSAudioApp
//
//  Created by 32BT on 27/01/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSKaraokeViewController.h"

#import "RMSAudio.h"
#import "RMSMixerSourceController.h"


@interface RMSKaraokeViewController ()

@property (nonatomic) RMSOutput *audioOutput;
@property (nonatomic) RMSMixer *mixer;

@property (nonatomic) RMSMixerSourceController *fileController;

@end

@implementation RMSKaraokeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
	
	self.audioOutput = [RMSOutput defaultOutput];
	
	self.mixer = [RMSMixer new];
	self.audioOutput.source = self.mixer;
	
	[self startDefaultInput];
}

////////////////////////////////////////////////////////////////////////////////

- (void) startDefaultInput
{
	// Get RMSSource instance for default input
	id src = [RMSInput defaultInput];

	// Embed in RMSMixerSource
	src = [self.mixer addSource:src];

	// Create viewController with mixerSource
	src = [RMSMixerSourceController instanceWithSource:src];
	
	// Add to main view
	[self addMixerSourceController:src];
}

////////////////////////////////////////////////////////////////////////////////

- (void) addMixerSourceController:(RMSMixerSourceController *)sourceController
{
	NSRect dstBounds = self.view.frame;
	NSRect srcFrame = sourceController.view.frame;
	
	srcFrame.origin.y = dstBounds.origin.y + dstBounds.size.height - srcFrame.size.height;
	
	sourceController.view.frame = srcFrame;
	[self addChildViewController:sourceController];
	[self.view addSubview:sourceController.view];
}

////////////////////////////////////////////////////////////////////////////////

- (IBAction) didSelectFileButton:(NSButton *)button
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

////////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
