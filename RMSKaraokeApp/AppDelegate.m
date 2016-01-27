//
//  AppDelegate.m
//  RMSKaraokeApp
//
//  Created by 32BT on 27/01/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "AppDelegate.h"
#import "RMSKaraokeViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	self.window.contentViewController = [RMSKaraokeViewController new];
	self.window.contentView = self.window.contentViewController.view;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
