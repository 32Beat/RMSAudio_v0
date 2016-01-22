////////////////////////////////////////////////////////////////////////////////
/*
	rmsdelay_t.h
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef rmsdelay_t_h
#define rmsdelay_t_h

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

////////////////////////////////////////////////////////////////////////////////
/*
	usage indication:
 
*/
////////////////////////////////////////////////////////////////////////////////

typedef struct rmsdelay_t
{
	float feedBack;
	uint32_t offset;
	
	uint64_t index;
	uint64_t indexMask;
	uint32_t frameCount;
	float *buffer;
}
rmsdelay_t;


////////////////////////////////////////////////////////////////////////////////

rmsdelay_t RMSDelayNew(void);
rmsdelay_t RMSDelayInit(uint32_t frameCount);
void RMSDelayReleaseMemory(rmsdelay_t *delay);

////////////////////////////////////////////////////////////////////////////////

void RMSDelaySetDelayTime(rmsdelay_t *delay, double time);
void RMSDelaySetSampleRate(rmsdelay_t *delay, double rate);

void RMSDelayProcessSamples(rmsdelay_t *delay, uint32_t newOffset, float newFeedBack, float *ptr, uint32_t count);

////////////////////////////////////////////////////////////////////////////////
#endif // rmslevels_h
////////////////////////////////////////////////////////////////////////////////





