////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSpectrogram.h"
#import <Accelerate/Accelerate.h>




@interface RMSSpectrogram ()
{
	size_t mDCTCount;
	size_t mDCTShift;
	
	// sliding buffers for left and right samples
	float *mL;
	float *mR;
	// write index for sliding buffer
	size_t mDstIndex;

	// working buffers
	float *mW; // tabulated window function

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

static inline void DCTWindowFunctionPrepareSin2(float *W, size_t size)
{
	// initialize window function
	for (UInt32 n=0; n!=size; n++)
	{
		float x = (1.0*n + 0.5)/size;
		float y = sin(x*M_PI);
		W[n] = y*y;
	}
}

////////////////////////////////////////////////////////////////////////////////

static inline void DCT_ValueToColor(float V, Byte *dstPtr)
{
	static const float colorSpectrum[][4] = {
	{ 0.0, 0.0, 0.0, 1.0 }, // black
	{ 0.0, 0.0, 1.0, 1.0 }, // blue
	{ 0.0, 1.0, 1.0, 1.0 }, // cyan
	{ 0.0, 1.0, 0.0, 1.0 }, // green
	{ 1.0, 1.0, 0.0, 1.0 }, // yellow
	{ 1.0, 0.0, 0.0, 1.0 }, // red
	{ 1.0, 0.0, 1.0, 1.0 }, // magenta
	{ 1.0, 1.0, 1.0, 1.0 }}; // white
	
	// compute spectrum power
	V = V*V;
	
	// limit to 1.0
	V /= (.5 + V);
	
	// index up to red
	V *= 5.0;
	
	long n = V;
	float R = colorSpectrum[n][0];
	float G = colorSpectrum[n][1];
	float B = colorSpectrum[n][2];

	float r = V - floor(V);
	if (r != 0)
	{
		R += r * (colorSpectrum[n+1][0] - R);
		G += r * (colorSpectrum[n+1][1] - G);
		B += r * (colorSpectrum[n+1][2] - B);
	}
	
	dstPtr[0] = 255*R + 0.5;
	dstPtr[1] = 255*G + 0.5;
	dstPtr[2] = 255*B + 0.5;
	dstPtr[3] = 255;
}


static inline void _DCT_to_Image(float *srcPtr, Byte *dstPtr, long n)
{
	float *srcPtrL = srcPtr-1;
	float *srcPtrR = srcPtr+n;
	// Move to center of image
	dstPtr += n<<2;
	
	while (n != 0)
	{
		DCT_ValueToColor(srcPtrL[n], &dstPtr[-n<<2]);
		n -= 1;
		DCT_ValueToColor(srcPtrR[n], &dstPtr[+n<<2]);
	}
}

////////////////////////////////////////////////////////////////////////////////

// Copy for sliding buffer
static inline void _CopySamples(
	float *srcL, float *dstL,
	float *srcR, float *dstR, size_t n)
{
	while (n != 0)
	{
		n -= 1;
		dstL[n] = srcL[n];
		dstR[n] = srcR[n];
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
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
	
	// Copy incoming audio...
	float *srcPtrL = bufferList->mBuffers[0].mData;
	float *srcPtrR = bufferList->mBuffers[1].mData;
	
	// ... to sliding buffers
	float *dstPtrL = rmsObject->mL;
	float *dstPtrR = rmsObject->mR;
	
	size_t dstIndex = rmsObject->mDstIndex;
	size_t dctCount = rmsObject->mDCTCount;
	size_t dctShift = rmsObject->mDCTShift;
	
	for (size_t n=0; n!=frameCount; n++)
	{
		// Copy incoming audio to sliding buffers
		dstPtrL[dstIndex] = srcPtrL[n];
		dstPtrR[dstIndex] = srcPtrR[n];
		dstIndex += 1;
		
		// If sliding buffer full, compute DCT into spectrumData
		if (dstIndex == dctCount)
		{
			float *spectrumData = rmsObject->mSpectrumData;
			UInt32 spectrumIndex = rmsObject->mSpectrumIndex & 255;
			
			// Move to current row
			spectrumData += spectrumIndex << (dctShift + 1);

			// Convert left signal into left side of spectrumdata
			vDSP_vmul(rmsObject->mL, 1, rmsObject->mW, 1, spectrumData, 1, dctCount);
			vDSP_DCT_Execute(rmsObject->mDCTSetup, spectrumData, spectrumData);

			// Move to center of row
			spectrumData += dctCount;
			
			// Convert right signal into right side of spectrumdata
			vDSP_vmul(rmsObject->mR, 1, rmsObject->mW, 1, spectrumData, 1, dctCount);
			vDSP_DCT_Execute(rmsObject->mDCTSetup, spectrumData, spectrumData);

			// Update index
			rmsObject->mSpectrumIndex += 1;


			// Move second half of buffer to start of buffer
			_CopySamples(
			&dstPtrL[dctCount/2], &dstPtrL[0],
			&dstPtrR[dctCount/2], &dstPtrR[0], dctCount/2);
			
			// Reset index to refill second half of buffer
			dstIndex = dctCount/2;
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
{ return [self initWithLength:512]; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithLength:(size_t)N
{
	self = [super init];
	if (self != nil)
	{
		mDCTShift = round(log2(N));
		mDCTCount = 1 << mDCTShift;
		
		
		// initialize sliding audio buffers
		mL = calloc(mDCTCount, sizeof(float));
		if (mL == nil) return nil;
		
		mR = calloc(mDCTCount, sizeof(float));
		if (mR == nil) return nil;
		
		// initialize window buffer
		mW = calloc(mDCTCount, sizeof(float));
		if (mW == nil) return nil;

		// initialize DCT setup
		mDCTSetup = vDSP_DCT_CreateSetup(nil, mDCTCount, vDSP_DCT_IV);
		if (mDCTSetup == nil) return nil;
		
		// initialize result buffer
		mSpectrumData = calloc(2 * mDCTCount * 256, sizeof(float));
		if (mSpectrumData == nil) return nil;
		
		
		// populate window table
		DCTWindowFunctionPrepareSin2(mW, mDCTCount);
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

	if (mW != nil)
	{
		free(mW);
		mW = nil;
	}
	
	if (mL != nil)
	{
		free(mL);
		mL = nil;
	}
	
	if (mR != nil)
	{
		free(mR);
		mR = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
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
		pixelsWide:mDCTCount * 2
		pixelsHigh:256
		bitsPerSample:32
		samplesPerPixel:1
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSCalibratedWhiteColorSpace
		bitmapFormat:NSFloatingPointSamplesBitmapFormat
		bytesPerRow:2 * mDCTCount * sizeof(float)
		bitsPerPixel:8 * sizeof(float)];
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
		pixelsWide:mDCTCount * 2
		pixelsHigh:range.length
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:mDCTCount * 2 * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];

	float *srcPtr = mSpectrumData;
	Byte *dstPtr = bitmap.bitmapData;
	
	// spectrum data is appended downward
	srcPtr += 2 * mDCTCount * (range.location&=255);
	// image data needs to be copied bottom to top
	dstPtr += 8 * mDCTCount * (range.length-1);
	
	
	for (UInt32 n=0; n!=range.length; n++)
	{
		_DCT_to_Image(srcPtr, dstPtr, mDCTCount);
		srcPtr += 2*mDCTCount;
		dstPtr -= 2*mDCTCount*4;
		
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

NSBitmapImageRep *NSBitmapImageRepWithSize(size_t W, size_t H)
{
	return [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:W
		pixelsHigh:H
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:W * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static void _Copy32f(float *srcPtr, float *dstPtr, UInt32 n)
{
	memcpy(dstPtr, srcPtr, n*sizeof(float));
}

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image
{
	UInt32 W = round(image.size.width);
	UInt32 H = round(image.size.height);

	H = 256 * H / W;
	W = 256;
//	H += H;
	
	NSBitmapImageRep *bitmap = NSBitmapImageRepWithSize(W, H);
	if (bitmap != nil)
	{
		NSGraphicsContext *context =
		[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
		
		[NSGraphicsContext setCurrentContext:context];
		
		[image drawInRect:(NSRect){0.0, 0.0, W, H }];
		
		return [self computeSampleBufferUsingBitmapImageRep:bitmap];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

void MDCT_Fold(float *srcPtr, float *dstPtr, size_t dstSize)
{
	size_t N = dstSize/2;
	float *a = &srcPtr[0*N];
	float *b = &srcPtr[1*N];
	float *c = &srcPtr[2*N];
	float *d = &srcPtr[3*N];
	
	for (size_t n=0; n!=N; n++)
	{
		dstPtr[n] = -c[N-1-n] - d[n];
	}
	
	dstPtr += N;
	
	for (size_t n=0; n!=N; n++)
	{
		dstPtr[n] = a[n] - b[N-1-n];
	}
}



+ (RMSClip *) computeSampleBufferUsingBitmapImageRep:(NSBitmapImageRep *)bitmap
{
	RMSClip *clip = nil;
	
	
	NSInteger W = bitmap.pixelsWide;
	NSInteger H = bitmap.pixelsHigh;

	
	// initialize DCT setup
	vDSP_DFT_Setup dctSetup = vDSP_DCT_CreateSetup(nil, W, vDSP_DCT_IV);
	if (dctSetup != nil)
	{

		float *F = calloc(W, sizeof(float));
		if (F != nil)
		{
			float *tmpPtr = calloc(W, sizeof(float));
			if (tmpPtr != nil)
			{
				for (long n=0; n!=W; n++)
				{
					float x = (1.0*n + 0.5)/W;
					float y = sin(x*M_PI);
					F[n] = 1-1*y*y;
				}

				
				
				clip = [[RMSClip alloc] initWithLength:(H+1) * (W/2)];
				if (clip != nil)
				{
					Byte *srcPtr = [bitmap bitmapData];
					float *dstPtr = clip.mutablePtrL;
					dstPtr += (H+1) * (W/2) - W;

					for (UInt32 y=0; y!=H; y++)
					{
						for (UInt32 x=0; x!=W; x++)
						{
							long R = srcPtr[0];
							long G = srcPtr[1];
							long B = srcPtr[2];
							srcPtr += 4;

							tmpPtr[x] = (3*R + 4*G + B) / (8*255.0);
						}

						vDSP_DCT_Execute(dctSetup, tmpPtr, tmpPtr);
						vDSP_vma(F, 1, tmpPtr, 1, dstPtr, 1, dstPtr, 1, W);
						
						srcPtr += bitmap.bytesPerRow - 4*W;
						dstPtr -= W/2;
						
						
					}
				
					_Copy32f(clip.mutablePtrL, clip.mutablePtrR, clip.sampleCount);
		
					[clip normalize];
				}
				
				free(tmpPtr);
			}
			
			free(F);
		}
		
		vDSP_DFT_DestroySetup(dctSetup);
	}
	
	return clip;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



