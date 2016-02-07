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

@property (nonatomic) RMSSource *micSource;
@property (nonatomic) RMSSource *filePlayer;
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
	self.micSource = [RMSInput defaultInput];

	// Pimp up the input with some oldskool delay
	[self.micSource addFilter:[RMSDelay spaceEcho]];


	
// TODO: need better separation from mixersource
/*
	[self.mixer addSource:] is intuitive, 
	but returning a mixersource is not 
	
	probably better strategy: create RMSMixerViewController
*/

	// Embed in RMSMixerSource
	id src = [self.mixer addSource:self.micSource];

	// Create viewController with mixerSource
	src = [RMSMixerSourceController instanceWithSource:src];
	
	// Add to main view
	[self addMixerSourceController:src];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setFilePlayer:(RMSSource *)filePlayer
{
	if (_filePlayer != nil)
	{ [self.mixer removeSource:_filePlayer]; }

	// Embed in mixersource
	id src = [self.mixer addSource:filePlayer];
	
	// Set in viewController
	[self.fileController setSource:src];
}

////////////////////////////////////////////////////////////////////////////////

- (RMSMixerSourceController *)fileController
{
	if (_fileController == nil)
	{
		_fileController = [RMSMixerSourceController instanceWithSource:nil];
		[self addMixerSourceController:_fileController];
	}
	
	return _fileController;
}

////////////////////////////////////////////////////////////////////////////////

- (void) addMixerSourceController:(RMSMixerSourceController *)sourceController
{
	NSRect dstBounds = self.view.frame;
	NSRect srcFrame = sourceController.view.frame;
	
	srcFrame.origin.y = dstBounds.origin.y + dstBounds.size.height;
	srcFrame.origin.y -= srcFrame.size.height + 
	self.childViewControllers.count * srcFrame.size.height;
	
	sourceController.view.frame = srcFrame;
	[self addChildViewController:sourceController];
	[self.view addSubview:sourceController.view];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (IBAction) didSelectFileButton:(NSButton *)button
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	panel.allowedFileTypes = [RMSAudioUnitFilePlayer readableTypes];

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
	
	// Set new source
	self.filePlayer = source;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
