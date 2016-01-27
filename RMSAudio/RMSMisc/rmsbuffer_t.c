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


////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

rmsbuffer_t RMSBufferBegin(size_t maxSampleCount)
{
	size_t sampleCount = 2;
	while (sampleCount < maxSampleCount)
	{ sampleCount <<= 1; }
	
	return (rmsbuffer_t){
		.index = 0,
		.indexMask = sampleCount-1,
		.sampleData = calloc(sampleCount, sizeof(float)) };
}

////////////////////////////////////////////////////////////////////////////////

void RMSBufferEnd(rmsbuffer_t *buffer)
{
	if (buffer != NULL)
	{
		if (buffer->sampleData != NULL)
		{
			free(buffer->sampleData);
			buffer->sampleData = NULL;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

rmsbuffer_t *RMSBufferNew(size_t maxSampleCount)
{
	rmsbuffer_t *bufferPtr = malloc(sizeof(rmsbuffer_t));
	if (bufferPtr != NULL)
	{
		bufferPtr[0] = RMSBufferBegin(maxSampleCount);
		if (bufferPtr->sampleData != NULL)
		{
			return bufferPtr;
		}
		
		free(bufferPtr);
	}
	
	return NULL;
}

////////////////////////////////////////////////////////////////////////////////

rmsbuffer_t *RMSBufferRelease(rmsbuffer_t *bufferPtr)
{
	if (bufferPtr != NULL)
	{
		if (bufferPtr->sampleData != NULL)
		{ free(bufferPtr->sampleData); }

		free(bufferPtr);
	}
	
	return NULL;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

void RMSBufferClearSamples(rmsbuffer_t *bufferPtr)
{
	if (bufferPtr && bufferPtr->sampleData)
	{
		uint64_t n = (bufferPtr->indexMask + 1) >> 1;

		while (n != 0)
		{ ((uint64_t *)bufferPtr->sampleData)[(n -= 1)] = 0; }
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSampleAtIndex(rmsbuffer_t *buffer, int64_t index)
{ return buffer->sampleData[index&buffer->indexMask]; }

void RMSBufferSetSampleAtIndex(rmsbuffer_t *buffer, int64_t index, float S)
{ buffer->sampleData[index&buffer->indexMask] = S; }

float RMSBufferGetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset)
{ return RMSBufferGetSampleAtIndex(buffer, buffer->index+offset); }

void RMSBufferSetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset, float S)
{ RMSBufferSetSampleAtIndex(buffer, buffer->index+offset, S); }

////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSample(rmsbuffer_t *buffer)
{ return RMSBufferGetSampleAtIndex(buffer, buffer->index); }

void RMSBufferSetSample(rmsbuffer_t *buffer, float S)
{ RMSBufferSetSampleAtIndex(buffer, buffer->index, S); }

void RMSBufferWriteSample(rmsbuffer_t *buffer, float S)
{ RMSBufferSetSampleAtIndex(buffer, buffer->index, S); buffer->index++; }

////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetSampleWithDelay(rmsbuffer_t *buffer, uint64_t sampleDelay)
{
	uint64_t index = buffer->index;
	uint64_t indexMask = buffer->indexMask;	
	return buffer->sampleData[(index-sampleDelay)&indexMask];
}

////////////////////////////////////////////////////////////////////////////////

float RMSBufferGetValueWithDelay(rmsbuffer_t *buffer, float sampleDelay)
{
	uint64_t index = buffer->index;
	uint64_t indexMask = buffer->indexMask;
	
	index -= (int64_t)sampleDelay;
	float R0 = buffer->sampleData[(index-0)&indexMask];
	float R1 = buffer->sampleData[(index-1)&indexMask];
	
	float M = sampleDelay - truncf(sampleDelay);
	
	return R0 + M * (R1 - R0);
}

////////////////////////////////////////////////////////////////////////////////

float RMSBufferStepSizeForFrequency(rmsbuffer_t *buffer, float F)
{ return F / (buffer->indexMask + 1.0); }

float RMSBufferValueAtOffset(rmsbuffer_t *buffer, double offset)
{
	uint64_t index = offset;
	uint64_t indexMask = buffer->indexMask;
	
	float R0 = buffer->sampleData[(index+0)&indexMask];
	float R1 = buffer->sampleData[(index+1)&indexMask];
	
	float M = offset - truncf(offset);
	
	return R0 + M * (R1 - R0);
}

////////////////////////////////////////////////////////////////////////////////



