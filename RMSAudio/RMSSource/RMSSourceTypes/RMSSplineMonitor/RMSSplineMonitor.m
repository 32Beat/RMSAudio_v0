////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSplineMonitor.h"
#import <Accelerate/Accelerate.h>






@interface RMSSplineMonitor ()
{
	UInt64 mN;
	
	double mE[kRMSSplineMonitorCount];
	long mMinIndex;
	long mMaxIndex;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitor
////////////////////////////////////////////////////////////////////////////////

static double FetchSample(float *srcPtr)
{ return srcPtr[0]+srcPtr[1]+srcPtr[1]+srcPtr[2]; }
static double FetchSample1(float *srcPtr)
{ return srcPtr[0]; }

static double Bezier
(double x, double P1, double C1, double C2, double P2)
{
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);
	C2 += x * (P2 - C2);
	
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);

	P1 += x * (C1 - P1);

	return P1;
}

////////////////////////////////////////////////////////////////////////////////

static double Interpolate
(double a, double x, double Y0, double Y1, double Y2, double Y3)
{
	double d1 = a * (Y2 - Y0) / 2.0;
	double d2 = a * (Y3 - Y1) / 2.0;
	return Bezier(x, Y1, Y1+d1, Y2-d2, Y2);
}

////////////////////////////////////////////////////////////////////////////////

static double ComputeError(double a, float *srcPtr)
{
	double S1 = FetchSample(&srcPtr[0]);
	double S2 = FetchSample(&srcPtr[2]);
	double S3 = FetchSample(&srcPtr[4]);
	double S4 = FetchSample(&srcPtr[6]);
	
	double S = FetchSample(&srcPtr[3]);
	double L = Interpolate(a, 0.5, S1, S2, S3, S4);
	
	L -= S;
	L *= 0.25;
	
	return L*L;
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
	__unsafe_unretained RMSSplineMonitor *rmsObject = \
	(__bridge __unsafe_unretained RMSSplineMonitor *)inRefCon;
	
	float *srcPtrL = bufferList->mBuffers[0].mData;
	float *srcPtrR = bufferList->mBuffers[1].mData;
	
	UInt64 N = rmsObject->mN;
	
	for (UInt32 n=0; n!=frameCount-8; n++)
	{
/*
		long X = 50 + 50 * srcPtrR[n];
		long Y = 50 + 50 * srcPtrL[n];
		if (X < 0) X = 0;
		if (X > 100) X = 100;
		if (Y < 0) Y = 0;
		if (Y > 100) Y = 100;

		rmsObject->mE[Y][X] += 1;
//*/

		double a = 1.0 * N / (kRMSSplineMonitorCount-1);
		
		rmsObject->mE[N] += ComputeError(a, &srcPtrL[n]);
		rmsObject->mE[N] += ComputeError(a, &srcPtrR[n]);

		N += 37;
		N &= (kRMSSplineMonitorCount-1);
//		if (N == kRMSSplineMonitorCount)
//		{ N = 0; }

	}
	
	rmsObject->mN = N;
	
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
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
}

////////////////////////////////////////////////////////////////////////////////

- (void) getErrorData:(double *)resultPtr minValue:(double *)minValuePtr
{
	memcpy(resultPtr, mE, kRMSSplineMonitorCount * sizeof(double));
	
	double min = resultPtr[0];
	double max = resultPtr[0];
	
	for (long n=1; n!=kRMSSplineMonitorCount; n++)
	{
		if (min > resultPtr[n])
		{ min = resultPtr[n]; }
		else
		if (max < resultPtr[n])
		{ max = resultPtr[n]; }
	}
	
	if (max > min)
	{
		for (long n=0; n!=kRMSSplineMonitorCount; n++)
		{
			resultPtr[n] = (resultPtr[n] - min)/(max - min);
		}
	}

	double A1 = resultPtr[0];
	double A2 = resultPtr[kRMSSplineMonitorCount-1];
	double A = A1 < A2 ? 1.0 - 1.0/(1.0+sqrt(A1)) : 1.0/(1.0+sqrt(A2));

	if (minValuePtr != nil)
	*minValuePtr = A;
}

////////////////////////////////////////////////////////////////////////////////

- (double) minValueForErrorData:(const double *)dataPtr
{
	double min = dataPtr[0];
	double max = dataPtr[0];
	
	for (long n=1; n!=kRMSSplineMonitorCount; n++)
	{
		if (min > dataPtr[n])
		{ min = dataPtr[n]; }
		else
		if (max < dataPtr[n])
		{ max = dataPtr[n]; }
	}

	double A1 = dataPtr[0];
	double A2 = dataPtr[kRMSSplineMonitorCount-1];
	
	A1 = (A1 - min) / (max - min);
	A2 = (A2 - min) / (max - min);
	
	return A1 < A2 ? 1.0 - 1.0/(1.0+sqrt(A1)) : 1.0/(1.0+sqrt(A2));
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static inline UInt32 RGBAColorMake(UInt32 R, UInt32 G, UInt32 B)
{ return (255<<24)+(B<<16)+(G<<8)+(R<<0); }

static inline void DCT_ValueToColor(double A, double V, UInt32 *dstPtr)
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


static inline void _DCT_to_Image(float A, double *srcPtr, UInt32 *dstPtr, long n)
{
	while (n != 0)
	{
		n -= 1;
		DCT_ValueToColor(A, srcPtr[n], &dstPtr[n]);
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
- (NSBitmapImageRep *) imageRepWithGain:(UInt32)a
{
	double *srcPtr = &mE[0][0];
	
	double *tmpPtr = calloc(kRMSSplineMonitorCount*kRMSSplineMonitorCount, sizeof(double));
	memcpy(tmpPtr, srcPtr, kRMSSplineMonitorCount*kRMSSplineMonitorCount*sizeof(double));

	srcPtr = tmpPtr;
	double min = srcPtr[0];
	double max = srcPtr[0];
	for (UInt32 n=1; n!=kRMSSplineMonitorCount*kRMSSplineMonitorCount; n++)
	{
		if (min > srcPtr[n]) min = srcPtr[n];
		if (max < srcPtr[n]) max = srcPtr[n];
	}
	
	if (max > min)
	{
		for (UInt32 n=0; n!=kRMSSplineMonitorCount*kRMSSplineMonitorCount; n++)
		{
			srcPtr[n] = (srcPtr[n] - min) / (max - min);
		}
	}
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:kRMSSplineMonitorCount
		pixelsHigh:kRMSSplineMonitorCount
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:kRMSSplineMonitorCount * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];

	UInt32 *dstPtr = (UInt32 *)bitmap.bitmapData;
	
	float A = pow(10.0, a);
	
	for (UInt32 n=0; n!=kRMSSplineMonitorCount; n++)
	{
		_DCT_to_Image(A, srcPtr, dstPtr, kRMSSplineMonitorCount);
		srcPtr += kRMSSplineMonitorCount;
		dstPtr += kRMSSplineMonitorCount;
	}
	
	free(tmpPtr);
	
	return bitmap;
}
*/
////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



