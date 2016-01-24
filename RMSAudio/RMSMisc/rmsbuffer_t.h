////////////////////////////////////////////////////////////////////////////////
/*
	rmsbuffer_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef rmsbuffer_t_h
#define rmsbuffer_t_h

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

////////////////////////////////////////////////////////////////////////////////
/*
	usage indication:
 
*/
////////////////////////////////////////////////////////////////////////////////

typedef struct rmsbuffer_t
{
	uint64_t index;
	uint64_t indexMask;
	float *dataPtr;
}
rmsbuffer_t;

////////////////////////////////////////////////////////////////////////////////

// Start bufferstruct with initialized memory ptr
rmsbuffer_t RMSBufferNew(size_t sampleCount);

// Release memory ptr in bufferstruct
void RMSBufferReleaseMemory(rmsbuffer_t *buffer);

////////////////////////////////////////////////////////////////////////////////

// Get & Set sample at current index modulo buffersize
float RMSBufferGetSample(rmsbuffer_t *buffer);
void RMSBufferSetSample(rmsbuffer_t *buffer, float S);

// Get & Set sample at specific index modulo buffersize
float RMSBufferGetSampleAtIndex(rmsbuffer_t *buffer, int64_t index);
void RMSBufferSetSampleAtIndex(rmsbuffer_t *buffer, int64_t index, float S);

// Get & Set sample at (current index + offset) modulo buffersize
float RMSBufferGetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset);
void RMSBufferSetSampleAtOffset(rmsbuffer_t *buffer, int64_t offset, float S);

////////////////////////////////////////////////////////////////////////////////

// Get interpolated sample at fractional offset = -sampleDelay
float RMSBufferGetSampleWithDelay(rmsbuffer_t *buffer, double sampleDelay);

////////////////////////////////////////////////////////////////////////////////
#endif // rmslevels_h
////////////////////////////////////////////////////////////////////////////////






