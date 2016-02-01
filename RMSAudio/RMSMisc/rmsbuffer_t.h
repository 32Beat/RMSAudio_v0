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
#include <stdbool.h>

////////////////////////////////////////////////////////////////////////////////
/*
	rmsbuffer_t
	-----------
	Simple general purpose ringbuffer type (without multithreading guards)
	
	usage indication:
	start buffer with desired size
	
		rmsbuffer_t buffer = RMSBufferBegin(sampleCount);
	
	release internal memory when done
	
 		RMSBufferEnd(&buffer);
	
*/
////////////////////////////////////////////////////////////////////////////////

typedef struct rmsbuffer_t
{
	uint64_t index;
	uint64_t indexMask;
	float   *sampleData;
	float reserved[20];
}
rmsbuffer_t;

////////////////////////////////////////////////////////////////////////////////

// Create bufferstruct with internal memory
rmsbuffer_t *RMSBufferNew(size_t sampleCount);

// Release bufferstruct and internal memory
rmsbuffer_t *RMSBufferRelease(rmsbuffer_t *bufferPtr);

////////////////////////////////////////////////////////////////////////////////

// Start bufferstruct with internal memory
rmsbuffer_t RMSBufferBegin(size_t maxSampleCount);

// Release internal memory
void RMSBufferEnd(rmsbuffer_t *buffer);

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

// Get sample at offset = -sampleDelay
float RMSBufferGetSampleWithDelay(rmsbuffer_t *buffer, uint32_t sampleDelay);
float RMSBufferGetValueWithDelay(rmsbuffer_t *buffer, float sampleDelay);

// Set sample at current index modulo buffersize, then update index
void RMSBufferWriteSample(rmsbuffer_t *buffer, float S);

////////////////////////////////////////////////////////////////////////////////
#endif // rmsbuffer_t_h
////////////////////////////////////////////////////////////////////////////////






