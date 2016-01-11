//
//  AppDelegate.m
//  RMSAudioApp
//
//  Created by 32BT on 10/01/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	self.window.contentViewController = [MainViewController new];
	self.window.contentView = self.window.contentViewController.view;
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
