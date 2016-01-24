////////////////////////////////////////////////////////////////////////////////
/*
	rmsbuffer_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#include "rmsbuffer_t.h"
#include <math.h>


////////////////////////////////////////////////////////////////////////////////

static inline double rms_fma(double A, double M, double S) \
{ return A + M * (S - A); }

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

rmsbuffer_t RMSBufferNew(size_t maxSampleCount)
{
	rmsbuffer_t buffer = {
		.index = 0,
		.indexMask = 0,
		.dataPtr = NULL
	};

	size_t sampleCount = 2;
	while (sampleCount < maxSampleCount)
	{ sampleCount <<= 1; }
	
	buffer.indexMask = sampleCount - 1;
	buffer.dataPtr = calloc(sampleCount, sizeof(float));
	
	return buffer;
}

////////////////////////////////////////////////////////////////////////////////

void RMSBufferReleaseMemory(rmsbuffer_t *buffer)
{
	if (buffer != NULL)
	{
		if (buffer->dataPtr != NULL)
		{
			free(buffer->dataPtr);
			buffer->dataPtr = NULL;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSampleAtIndex(rmsbuffer_t *buffer, int64_t index)
{ return buffer->dataPtr[index&buffer->indexMask]; }

void RMSBufferSetSampleAtIndex(rmsbuffer_t *buffer, int64_t index, float S)
{ buffer->dataPtr[index&buffer->indexMask] = S; }

float RMSBufferGetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset)
{ return RMSBufferGetSampleAtIndex(buffer, buffer->index+offset); }

void RMSBufferSetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset, float S)
{ RMSBufferSetSampleAtIndex(buffer, buffer->index+offset, S); }

////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSample(rmsbuffer_t *buffer)
{ return RMSBufferGetSampleAtIndex(buffer, buffer->index); }

void RMSBufferSetSample(rmsbuffer_t *buffer, float S)
{ RMSBufferSetSampleAtIndex(buffer, buffer->index, S); }

////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSampleWithDelay(rmsbuffer_t *buffer, double sampleDelay)
{
	uint64_t index = buffer->index;
	uint64_t indexMask = buffer->indexMask;
	
	int64_t T = index - (int64_t)sampleDelay;
	float R1 = buffer->dataPtr[(T-0)&indexMask];
	float R2 = buffer->dataPtr[(T-1)&indexMask];
	return R1 + (sampleDelay-trunc(sampleDelay)) * (R2 - R1);
//	return fmaf((sampleDelay-trunc(sampleDelay)), (R2 - R1), R1);
}

////////////////////////////////////////////////////////////////////////////////



