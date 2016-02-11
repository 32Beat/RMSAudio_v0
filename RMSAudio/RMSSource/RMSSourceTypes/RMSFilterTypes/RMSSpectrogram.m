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
	float *mSpectrumData;
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
	float *dstPtr, int dstStep, UInt32 n)
{
	while(n != 0)
	{
		n -= 1;
		
		dstPtr[0] = srcPtr[0] * srcPtr[0];
		if (dstPtr[0] > 1.0) dstPtr[0] = 1.0;
		
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
			float *spectrumData = rmsObject->mSpectrumData;
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
		mSpectrumData = calloc(2 * kDCTCount * 256, sizeof(float));
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
		bitsPerSample:32
		samplesPerPixel:1
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSCalibratedWhiteColorSpace
		bitmapFormat:NSFloatingPointSamplesBitmapFormat
		bytesPerRow:2*kDCTCount * sizeof(float)
		bitsPerPixel:8 * sizeof(float)];
}

////////////////////////////////////////////////////////////////////////////////

static inline void CopyRow(void *src, void *dst)
{
	double *srcPtr = (double *)src;
	double *dstPtr = (double *)dst;
	
	UInt32 n = kDCTCount-1;
	do { dstPtr[n] = srcPtr[n]; } while(--n != 0);
	dstPtr[0] = srcPtr[0];
}


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
		bitsPerSample:32
		samplesPerPixel:1
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSCalibratedWhiteColorSpace
		bitmapFormat:NSFloatingPointSamplesBitmapFormat
		bytesPerRow:kDCTCount * 2 * sizeof(float)
		bitsPerPixel:8 * sizeof(float)];

	float *srcPtr = mSpectrumData;
	float *dstPtr = (float *)bitmap.bitmapData;
	
	// spectrum data is appended downward
	srcPtr += 2 * kDCTCount * (range.location&=255);
	// image data needs to be copied bottom to top
	dstPtr += 2 * kDCTCount * (range.length-1);
	
	for (UInt32 n=0; n!=range.length; n++)
	{
		CopyRow(srcPtr, dstPtr);
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
@end
////////////////////////////////////////////////////////////////////////////////



