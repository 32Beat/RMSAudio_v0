//
//  RMSSampleMap.m
//  RMSAudioApp
//
//  Created by 32BT on 16/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSampleMap.h"


#define kRMSSampleMapSize  64

@interface RMSSampleMap ()
{
	UInt32 mMap[kRMSSampleMapSize][kRMSSampleMapSize];
	UInt32 mMax;
	
	double mFilter;
}

@end


@implementation RMSSampleMap

#define CLIP(n, a, b) (((a)<=(n))?((n)<=(b))?(n):(b):(a));

- (void) processSamples:(float **)samplePtr count:(UInt32)count
{
	float *ptrL = samplePtr[0];
	float *ptrR = samplePtr[1];
	
	for (UInt32 n=0; n!=count; n++)
	{
		float L = ptrL[n];
		float R = ptrR[n];
		
		int x = 32 + 32 * 0.707 * (R - L);
		int y = 32 + 32 * 0.707 * (R + L);
		
		x = CLIP(x, 0, 63);
		y = CLIP(y, 0, 63);
		
		mMap[y][x] += 1;
		if (mMax < mMap[y][x])
		{ mMax = mMap[y][x]; }
	}
}

- (void) resetMap
{
	memset(mMap, 0, kRMSSampleMapSize*kRMSSampleMapSize*sizeof(UInt32));
	mMax = 0;
}

- (NSBitmapImageRep *) spectrumImageWithGain:(float)gain
{
	return nil;
}

@end






