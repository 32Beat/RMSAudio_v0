////////////////////////////////////////////////////////////////////////////////
/*
	rmsdelay_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#include "rmsdelay_t.h"
#include <math.h>


////////////////////////////////////////////////////////////////////////////////

static inline double rms_fma(double A, double M, double S) \
{ return A + M * (S - A); }

////////////////////////////////////////////////////////////////////////////////

void RMSDelayUpdateOffset(rmsdelay_t *delay);
void RMSDelaySetOffset(rmsdelay_t *delay, uint32_t offset);

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

rmsdelay_t RMSDelayNew(void)
{ return RMSDelayInit(1024*1024); }

////////////////////////////////////////////////////////////////////////////////

rmsdelay_t RMSDelayInit(uint32_t maxFrameCount)
{
	rmsdelay_t delay = {
		.feedBack = 0.0,
		.offset = 0,
		.index = 0,
		.indexMask = 0,
		.frameCount = 0,
		.buffer = NULL
	};
	
	uint32_t frameCount = 2;
	while (frameCount < maxFrameCount)
	{ frameCount <<= 1; }
	
	delay.indexMask = frameCount - 1;
	delay.frameCount = frameCount;
	delay.buffer = calloc(frameCount, sizeof(float));
	
	return delay;
}

////////////////////////////////////////////////////////////////////////////////

void RMSDelayReleaseMemory(rmsdelay_t *delay)
{
	if (delay && delay->buffer)
	{
		free(delay->buffer);
		delay->buffer = NULL;
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
void RMSDelaySetDelayTime(rmsdelay_t *delay, double time)
{
	delay->time = time;
	RMSDelayUpdateOffset(delay);
}

////////////////////////////////////////////////////////////////////////////////

void RMSDelaySetSampleRate(rmsdelay_t *delay, double rate)
{
	delay->sampleRate = rate;
	RMSDelayUpdateOffset(delay);
}

////////////////////////////////////////////////////////////////////////////////

void RMSDelayUpdateOffset(rmsdelay_t *delay)
{
	uint32_t offset = delay->time * delay->sampleRate;
	RMSDelaySetOffset(delay, offset);
}
*/
////////////////////////////////////////////////////////////////////////////////

void RMSDelaySetOffset(rmsdelay_t *delay, uint32_t offset)
{
	if (offset > delay->frameCount)
	{ offset = delay->frameCount; }

	delay->offset = offset;
}

////////////////////////////////////////////////////////////////////////////////

float RMSDelayProcessSample(rmsdelay_t *delay, float S)
{
	uint64_t index = delay->index++;
	uint64_t indexMask = delay->indexMask;
	float R = delay->buffer[(index-delay->offset)&indexMask];

	S += delay->feedBack * (R - S);
	
	delay->buffer[index&indexMask] = S;

	return R;
}

////////////////////////////////////////////////////////////////////////////////

void RMSDelayProcessSamples(rmsdelay_t *delay, uint32_t newOffset, float newFeedBack, float *ptr, uint32_t count)
{
	double T = delay->offset;
	double Tstep = 1.0 * (newOffset - T) / count;
	
	double F = delay->feedBack;
	double Fstep = 1.0 * (newFeedBack - F) / count;
	
	for (uint32_t n=0; n!=count; n++)
	{
		ptr[n] = RMSDelayProcessSample(delay, ptr[n]);
		delay->offset = (T += Tstep);
		delay->feedBack = (F += Fstep);
	}
}

////////////////////////////////////////////////////////////////////////////////



