////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSpectrogram.h"
#import <Accelerate/Accelerate.h>



// nr of samples used for DCT conversion
#define kDCTCount 	1024

// nr of samples between each conversion
#define kDCTStep 	512



@interface RMSSpectrogram ()
{
	// sliding buffers for left and right samples
	float mL[kDCTCount];
	float mR[kDCTCount];
	// write index for sliding buffer
	UInt32 mDstIndex;

	// working buffers
	float mW[kDCTCount]; // tabulated window function
	float mT[kDCTCount]; // temporary buffer

	// invariants for dct conversion
	vDSP_DFT_Setup mDCTSetup;
	
	// result buffer
	Byte *mSpectrumData;
	UInt64 mSpectrumIndex;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSpectrogram
////////////////////////////////////////////////////////////////////////////////

// forward copy for sliding buffer
static inline void _CopySamples(
	float *srcL, float *dstL,
	float *srcR, float *dstR,
	UInt32 count)
{
	for (UInt32 n=0; n!=count; n++)
	{
		dstL[n] = srcL[n];
		dstR[n] = srcR[n];
	}
}

// convert to power and clip
static inline void _DCT_to_Image(
	float *srcPtr, int srcStep,
	Byte *dstPtr, int dstStep, UInt32 n)
{
	while(n != 0)
	{
		n -= 1;
		
		long V = 255.0 * srcPtr[0] * srcPtr[0] + 0.5;
		dstPtr[0] = V < 255 ? V : 255;
		
		srcPtr += srcStep;
		dstPtr += dstStep;
	}
}

////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSSpectrogram *rmsObject = \
	(__bridge __unsafe_unretained RMSSpectrogram *)inRefCon;
	
	float *srcPtrL = bufferList->mBuffers[0].mData;
	float *srcPtrR = bufferList->mBuffers[1].mData;
	
	float *dstPtrL = rmsObject->mL;
	float *dstPtrR = rmsObject->mR;
	
	UInt32 dstIndex = rmsObject->mDstIndex;

	for (UInt32 n=0; n!=frameCount; n++)
	{
		dstPtrL[dstIndex] = srcPtrL[n];
		dstPtrR[dstIndex] = srcPtrR[n];
		dstIndex += 1;
		
		if (dstIndex == kDCTCount)
		{
			Byte *spectrumData = rmsObject->mSpectrumData;
			UInt32 spectrumIndex = rmsObject->mSpectrumIndex & 255;
			
			// Move to current row
			spectrumData += spectrumIndex * kDCTCount * 2;
			// Move to center of image
			spectrumData += kDCTCount;

			// Convert left signal
			vDSP_vmul(rmsObject->mL, 1, rmsObject->mW, 1, rmsObject->mT, 1, kDCTCount);
			vDSP_DCT_Execute(rmsObject->mDCTSetup, rmsObject->mT, rmsObject->mT);
			_DCT_to_Image(rmsObject->mT, 1, spectrumData-1, -1, kDCTCount);
			
			// Convert right signal
			vDSP_vmul(rmsObject->mR, 1, rmsObject->mW, 1, rmsObject->mT, 1, kDCTCount);
			vDSP_DCT_Execute(rmsObject->mDCTSetup, rmsObject->mT, rmsObject->mT);
			_DCT_to_Image(rmsObject->mT, 1, spectrumData, 1, kDCTCount);

			// Update index
			rmsObject->mSpectrumIndex += 1;

			// Shift source samples for sliding window
			_CopySamples(
			&dstPtrL[kDCTStep], &dstPtrL[0],
			&dstPtrR[kDCTStep], &dstPtrR[0], kDCTCount-kDCTStep);
			
			// Reset index
			dstIndex = kDCTCount - kDCTStep;
		}
	}
	
	rmsObject->mDstIndex = dstIndex;
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{
	self = [super init];
	if (self != nil)
	{
		// initialize DCT setup
		mDCTSetup = vDSP_DCT_CreateSetup(nil, kDCTCount, vDSP_DCT_IV);
		
		// initialize window function
		for (UInt32 n=0; n!=kDCTCount; n++)
		{
			float x = (1.0*n + 0.5)/kDCTCount;
			float y = sin(x*M_PI);
			mW[n] = y*y;
		}
		
		// initialize result buffer
		mSpectrumData = calloc(2 * kDCTCount * 256, sizeof(Byte));
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	if (mSpectrumData != nil)
	{
		free(mSpectrumData);
		mSpectrumData = nil;
	}
	
	if (mDCTSetup != nil)
	{
		vDSP_DFT_DestroySetup(mDCTSetup);
		mDCTSetup = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
	This creates a bitmap imagerep of the internal spectrum buffer
	The internal buffer is obviously being used by the audiothread 
	which may become visible when drawing the image
	
	We therefore implement an imageRepWithIndex method, which requests 
	an imageRep from a particular sliding step index. 
	mImgIndex is the current row index being computed, so every row
	from index to mImgIndex (ex) are copied to the image
*/
- (NSBitmapImageRep *) imageRep
{
	return [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:(Byte **)&mSpectrumData
		pixelsWide:kDCTCount * 2
		pixelsHigh:256
		bitsPerSample:8
		samplesPerPixel:1
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSCalibratedWhiteColorSpace
		bitmapFormat:0
		bytesPerRow:2*kDCTCount * sizeof(Byte)
		bitsPerPixel:8 * sizeof(Byte)];
}

////////////////////////////////////////////////////////////////////////////////

- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index
{
	// Keep reasonable margin 
	if (index < (mSpectrumIndex - 128))
	{ index = mSpectrumIndex - 128; }
	
	if (index < mSpectrumIndex)
	{
		NSRange R = { index&255, mSpectrumIndex-index };
		return [self imageRepWithRange:R];
	}

	return nil;
}


- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range
{
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:kDCTCount * 2
		pixelsHigh:range.length
		bitsPerSample:8
		samplesPerPixel:1
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSCalibratedWhiteColorSpace
		bitmapFormat:0
		bytesPerRow:kDCTCount * 2 * sizeof(Byte)
		bitsPerPixel:8 * sizeof(Byte)];

	Byte *srcPtr = mSpectrumData;
	Byte *dstPtr = bitmap.bitmapData;
	
	// spectrum data is appended downward
	srcPtr += 2 * kDCTCount * (range.location&=255);
	// image data needs to be copied bottom to top
	dstPtr += 2 * kDCTCount * (range.length-1);
	
	for (UInt32 n=0; n!=range.length; n++)
	{
		memcpy(dstPtr, srcPtr, 2*kDCTCount);
		srcPtr += 2*kDCTCount;
		dstPtr -= 2*kDCTCount;
		
		range.location += 1;
		if (range.location == 256)
		{
			srcPtr = mSpectrumData;
			range.location = 0;
		}
	}
	
	return bitmap;
}

////////////////////////////////////////////////////////////////////////////////

CGContextRef CGBitmapContextCreateRGBA8WithSize(size_t W, size_t H)
{
	CGContextRef context = nil;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	if (colorSpace != nil)
	{
		context = CGBitmapContextCreate(nil, W, H,
		8, 0, colorSpace, kCGImageAlphaLast);
		
		CGColorSpaceRelease(colorSpace);
	}
	
	return context;
}

////////////////////////////////////////////////////////////////////////////////

+ (float *) computeSampleBufferUsingImage:(NSImage *)image
{
	UInt32 W = round(image.size.width);
	UInt32 H = round(image.size.height);

	W += W&0x01;
	
	[image lockFocus];

	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
	initWithFocusedViewRect:(NSRect){ 0, 0, W, H }];
	
	[image unlockFocus];
	
	return [self computeSampleBufferUsingBitmapImageRep:bitmap];
}

////////////////////////////////////////////////////////////////////////////////

+ (float *) computeSampleBufferUsingBitmapImageRep:(NSBitmapImageRep *)bitmap
{
	UInt32 W = bitmap.pixelsWide;
	UInt32 H = bitmap.pixelsHigh;

	W += W&0x01;
	
	UInt32 N = (H+1) * (W/2);
	float *ptr = calloc(N, sizeof(float));
	
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



