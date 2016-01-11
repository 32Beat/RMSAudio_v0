//
//  RMSMixerSourceController.h
//  TheEngineSample
//
//  Created by 32BT on 25/12/15.
//  Copyright © 2015 A Tasty Pixel. All rights reserved.
//


#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#define NSViewController UIViewController
#define NSButton UIButton
#define NSSlider UISlider
#endif

#import "RMSMixerSource.h"
#import "RMSStereoView.h"
#import "RMSTimer.h"

@interface RMSMixerSourceController : NSViewController <RMSTimerProtocol>
{
	RMSMixerSource *mSource;
}
@property (nonatomic, weak) IBOutlet NSButton *playButton;
@property (nonatomic, weak) IBOutlet NSSlider *volumeSlider;
@property (nonatomic, weak) IBOutlet NSSlider *balanceSlider;
@property (nonatomic, weak) IBOutlet RMSStereoView *stereoView;


+ (instancetype) instanceWithSource:(RMSMixerSource *)source;
- (instancetype) initWithSource:(RMSMixerSource *)source;

- (IBAction) didAdjustSlider:(NSSlider *)slider;

@end
