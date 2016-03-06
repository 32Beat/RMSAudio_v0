////////////////////////////////////////////////////////////////////////////////
/*
	rmsoscillator_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#include "rmsoscillator_t.h"
#include <math.h>
#include <stdlib.h>


////////////////////////////////////////////////////////////////////////////////

static double sineWave(double x)
{ return sin(x*M_PI); }

static double triangleWave(double x)
{ return (x += x) < 0.0 ? x + 1.0 : 1.0 - x; }

static double pseudoSineWave(double x)
{ return (x += x) < 0.0 ? x*(2.0+x) : x*(2.0-x); }

////////////////////////////////////////////////////////////////////////////////

rmsoscillator_t RMSOscillatorBegin(double (*functionPtr)(double), double Hz, double phase)
{
	// X = [-1.0, ..., +1.0], stepcycle = 2.0
	double step = 2.0 * Hz / 44100.0;
	
	return (rmsoscillator_t)
	{
		.Hz = Hz,
		.Fs = 44100,
		.X = (phase-1.0)-step,
		.dX = step,
		.functionPtr = functionPtr
	};
}

////////////////////////////////////////////////////////////////////////////////

rmsoscillator_t RMSOscillatorBeginSineWave(double hertz, double phase)
{ return RMSOscillatorBegin(sineWave, hertz, phase); }

rmsoscillator_t RMSOscillatorBeginPseudoSineWave(double hertz, double phase)
{ return RMSOscillatorBegin(pseudoSineWave, hertz, phase); }

rmsoscillator_t RMSOscillatorBeginTriangleWave(double hertz, double phase)
{ return RMSOscillatorBegin(triangleWave, hertz, phase); }

////////////////////////////////////////////////////////////////////////////////
/*
	X runs from -1.0 to +1.0, so dX needs to be twice the cycle step
*/
void RMSOscillatorUpdateStep(rmsoscillator_t *oscPtr)
{
	double Hz = oscPtr->Hz;
	double Fs = oscPtr->Fs;

	oscPtr->dX = 2.0 * Hz / (Fs != 0.0 ? Fs : 44100.0);
}

////////////////////////////////////////////////////////////////////////////////

void RMSOscillatorSetFrequency(rmsoscillator_t *oscPtr, double Hz)
{
	oscPtr->Hz = Hz;
	RMSOscillatorUpdateStep(oscPtr);
}

void RMSOscillatorSetSampleRate(rmsoscillator_t *oscPtr, double Fs)
{
	oscPtr->Fs = Fs;
	RMSOscillatorUpdateStep(oscPtr);
}

////////////////////////////////////////////////////////////////////////////////

double RMSOscillatorFetchSample(rmsoscillator_t *oscPtr)
{
	oscPtr->X += oscPtr->dX;
	if (oscPtr->X >= 1.0)
	{ oscPtr->X -= 2.0; }
	return oscPtr->functionPtr ? oscPtr->functionPtr(oscPtr->X) : oscPtr->X;
}

////////////////////////////////////////////////////////////////////////////////

double RMSOscillatorFetchSampleRA(rmsoscillator_t *oscPtr)
{
	oscPtr->X += oscPtr->dX;
	if (oscPtr->X > +oscPtr->A)
	{
		oscPtr->X = +oscPtr->A;
		oscPtr->dX = -oscPtr->dX;
	}
	else
	if (oscPtr->X < -oscPtr->A)
	{
		oscPtr->X = -oscPtr->A;
		oscPtr->dX = -oscPtr->dX;
		oscPtr->A = 0.1 + 0.9 * random() / RAND_MAX;
	}
	
	return oscPtr->X;
}

////////////////////////////////////////////////////////////////////////////////




