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
#pragma mark
////////////////////////////////////////////////////////////////////////////////

rmsdelay_t RMSDelayBegin(void)
{ return RMSBufferBegin(1024*1024); }

rmsdelay_t RMSDelayBeginWithSize(size_t size)
{
	long L = ceil(log2(size));
	return RMSBufferBegin(1<<L);
}

////////////////////////////////////////////////////////////////////////////////

void RMSDelayEnd(rmsdelay_t *delay)
{ return RMSBufferEnd(delay); }

////////////////////////////////////////////////////////////////////////////////

float RMSDelayExchangeSample(rmsdelay_t *delay, float S)
{
	float R = RMSBufferGetSample(delay);
	RMSBufferWriteSample(delay, S);
	return R;
}

////////////////////////////////////////////////////////////////////////////////

float _RMSDelayProcessSample(rmsdelay_t *delay, float offset, float feedBack, float S)
{
	float R = RMSBufferGetSampleWithDelay(delay, offset);
	
	S += feedBack * R;
	
	RMSBufferWriteSample(delay, S);
	
	return S;
}

////////////////////////////////////////////////////////////////////////////////

float RMSDelayProcessSample(rmsdelay_t *delay, float offset, float feedBack, float S)
{
#define steps 8

	uint32_t T1 = 0;
	uint32_t T2 = offset;
	
	float R = 0;
	
	for (size_t n=steps; n!=0; n--)
	{
		R -= RMSBufferGetSampleWithDelay(delay, T2);
		T1 = 1 | ((T1+T2)>>1);
		R += RMSBufferGetSampleWithDelay(delay, T1);
		T2 = 1 | ((T1+T2)>>1);
	}
	
	R *= (1.0/steps);
	
//	R = (delay->reserved[0] += (1.0-feedBack) * (R - delay->reserved[0]));
	
	S += feedBack * R;
	
	RMSBufferWriteSample(delay, S);
	
	return S;
}

////////////////////////////////////////////////////////////////////////////////

float RMSDelayProcessSample2(rmsdelay_t *delay, float offset, float feedBack, float S)
{
#define steps 8

	uint32_t T1 = 0;
	uint32_t T2 = offset;
	
	float R = 0;
	
	for (size_t n=steps; n!=0; n--)
	{
		R += RMSBufferGetSampleWithDelay(delay, T2);
		T1 = 1 | ((T1+T2)>>1);
		R -= RMSBufferGetSampleWithDelay(delay, T1);
		T2 = 1 | ((T1+T2)>>1);
	}
	
	R *= (1.0/steps);
	
	S += feedBack * R;
	
	RMSBufferWriteSample(delay, S);
	
	return S;
}

////////////////////////////////////////////////////////////////////////////////

float RMSDelayProcessSampleMTF(rmsdelay_t *delay, float offset, float feedBack, float S)
{
#define steps 8

	float T1 = 0;
	float T2 = offset;
	
	float R = 0;
	for (size_t n=steps; n!=0; n--)
	{
		R += RMSBufferGetValueWithDelay(delay, T2);
		T1 = (T1+T2)*0.5;
		R -= RMSBufferGetValueWithDelay(delay, T1);
		T2 = (T1+T2)*0.5;
	}
	
	R *= (1.0/(steps));
	S += feedBack * R;
	
	RMSBufferWriteSample(delay, S);
	
	return S;
}

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////






