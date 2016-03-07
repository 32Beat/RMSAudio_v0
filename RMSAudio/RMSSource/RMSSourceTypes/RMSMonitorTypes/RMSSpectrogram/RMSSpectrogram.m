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

	// working buffer
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
			//vDSP_vrvrs(spectrumData, 1, dctCount);
			
			// Move to center of row
			spectrumData += dctCount;
			
			// Convert right signal into right side of spectrumdata
			vDSP_vmul(rmsObject->mR, 1, rmsObject->mW, 1, spectrumData, 1, dctCount);
			vDSP_DCT_Execute(rmsObject->mDCTSetup, spectrumData, spectrumData);
/*
			// move back to start of row
			spectrumData -= dctCount;
			
			// normalize entire row
			const float m = sqrt(2.0 / dctCount);
			vDSP_vsmul(spectrumData, 1, &m, spectrumData, 1, 2*dctCount);
//*/
/*
			// move back to start of row
			spectrumData -= dctCount;

			long previousRow = -2*dctCount;
			if (spectrumData == rmsObject->mSpectrumData)
			{ previousRow += 256*2*dctCount; }
			
			_DCT_Mix1(&spectrumData[previousRow], spectrumData, dctCount);
			spectrumData += dctCount;
			_DCT_Mix2(&spectrumData[previousRow], spectrumData, dctCount);
//*/

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
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static inline void PrepareDCTWindow(float *W, size_t size)
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

- (instancetype) init
{ return [self initWithLength:256]; }

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
		PrepareDCTWindow(mW, mDCTCount);
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

static inline UInt32 RGBAColorMake(UInt32 R, UInt32 G, UInt32 B)
{ return (255<<24)+(B<<16)+(G<<8)+(R<<0); }

static inline void DCT_ValueToColor(float A, float V, UInt32 *dstPtr)
{
#define CMX 255.0

	static const float colorSpectrum[][4] = {
	{ 0.0, 0.0, 0.0, CMX }, // black
	{ 0.0, 0.0, CMX, CMX }, // blue
	{ 0.0, CMX, CMX, CMX }, // cyan
	{ 0.0, CMX, 0.0, CMX }, // green
	{ CMX, CMX, 0.0, CMX }, // yellow
	{ CMX, 0.0, 0.0, CMX }, // red
	{ CMX, 0.0, CMX, CMX }, // magenta
	{ CMX, CMX, CMX, CMX }}; // white
	
	// compute spectrum power
	V = V*V;
	
	// amplify result
	V *= A;
	
	// limit to 1.0
	V /= (1.0 + V);
	
	// scale for index up to red
	V *= 5.0;
	
	// limit function guarantees n < 5
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
	
	dstPtr[0] = RGBAColorMake(R+0.5, G+0.5, B+0.5);
}


static inline void _DCT_to_Image(float A, float *srcPtr, UInt32 *dstPtr, long n)
{
	float *srcPtrL = srcPtr-1;
	float *srcPtrR = srcPtr+n;
	// Move to center of image
	dstPtr += n;
	
	while (n != 0)
	{
		DCT_ValueToColor(A, srcPtrL[n], &dstPtr[-n]);
		n -= 1;
		DCT_ValueToColor(A, srcPtrR[n], &dstPtr[+n]);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	imageRep
	--------
	This creates a bitmap imagerep of the internal spectrum buffer
	The internal buffer is continuously being used by the audiothread
	which may become visible when drawing the full image
	
	Useful for testing purposes
	
	For normal display purposes use imageRepWithIndex instead
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
/*
	imageRepWithIndex
	-----------------
	creates an imageRep from a particular sliding step index.
	mSpectrumIndex is the index of the row being computed by the audiothread, 
	so the bitmap will be based on the rows from index to mSpectrumIndex (ex)
*/

- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index
{ return [self imageRepWithIndex:index gain:0]; }

- (NSBitmapImageRep *) imageRepWithIndex:(UInt64)index gain:(UInt32)a
{
	// Keep reasonable margin 
	if (index < (mSpectrumIndex - 128))
	{ index = mSpectrumIndex - 128; }
	
	if (index < mSpectrumIndex)
	{
		NSRange R = { index&255, mSpectrumIndex-index };
		return [self imageRepWithRange:R gain:a];
	}

	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range
{ return [self imageRepWithRange:range gain:0]; }

- (NSBitmapImageRep *) imageRepWithRange:(NSRange)range gain:(UInt32)a
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
	UInt32 *dstPtr = (UInt32 *)bitmap.bitmapData;
	
	// spectrum data is appended downward
	srcPtr += 2 * mDCTCount * (range.location&=255);
	// image data needs to be copied bottom to top
	dstPtr += 2 * mDCTCount * (range.length-1);
	
	float A = pow(10.0, a);
	
	for (UInt32 n=0; n!=range.length; n++)
	{
		_DCT_to_Image(A, srcPtr, dstPtr, mDCTCount);
		srcPtr += 2*mDCTCount;
		dstPtr -= 2*mDCTCount;
		
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
#pragma mark
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

	H = 512 * H / W;
	W = 512;
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
					F[n] = 1-y*y;
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
						vDSP_vmul(F, 1, tmpPtr, 1, tmpPtr, 1, W);
						vDSP_vadd(tmpPtr, 1, dstPtr, 1, dstPtr, 1, W);
						
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



