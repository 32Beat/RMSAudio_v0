////////////////////////////////////////////////////////////////////////////////
/*
	rmsoscillator_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#ifndef rmsoscillator_t_h
#define rmsoscillator_t_h

#include <stddef.h>
#include <stdint.h>

////////////////////////////////////////////////////////////////////////////////
/*
	usage indication:
 
*/
////////////////////////////////////////////////////////////////////////////////

typedef struct rmsoscillator_t
{
	double Hz;
	double Fs;
	double X;
	double dX;
	double A;

	double (*functionPtr)(double);
}
rmsoscillator_t;

////////////////////////////////////////////////////////////////////////////////

rmsoscillator_t RMSOscillatorBeginSineWave(double hertz, double sampleRate);
rmsoscillator_t RMSOscillatorBeginPseudoSineWave(double hertz, double sampleRate);
rmsoscillator_t RMSOscillatorBeginTriangleWave(double hertz, double sampleRate);
rmsoscillator_t RMSOscillatorBegin(double (*functionPtr)(double), double Hz, double phase);

void RMSOscillatorSetSampleRate(rmsoscillator_t *oscPtr, double Fs);
void RMSOscillatorSetFrequency(rmsoscillator_t *oscPtr, double Hz);

double RMSOscillatorFetchSample(rmsoscillator_t *oscPtr);
double RMSOscillatorFetchSampleRA(rmsoscillator_t *oscPtr);

////////////////////////////////////////////////////////////////////////////////
#endif // rmsoscillator_t_h
////////////////////////////////////////////////////////////////////////////////






