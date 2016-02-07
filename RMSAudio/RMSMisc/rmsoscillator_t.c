////////////////////////////////////////////////////////////////////////////////
/*
	rmsoscillator_t
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#include "rmsoscillator_t.h"
#include <math.h>


////////////////////////////////////////////////////////////////////////////////

static double sineWave(double x)
{ return sin(x*M_PI); }

static double triangleWave(double x)
{ return (x += x) < 0.0 ? x + 1.0 : 1.0 - x; }

static double pseudoSineWave(double x)
{ return (x += x) < 0.0 ? x*(2.0+x) : x*(2.0-x); }

////////////////////////////////////////////////////////////////////////////////

rmsoscillator_t RMSOscillatorBegin(double hertz, double sampleRate, double (*functionPtr)(double))
{
	double step = hertz / sampleRate;
	
	return (rmsoscillator_t){
		.X = -.5*step,
		.Xstep = step,
		.functionPtr = functionPtr };
}

////////////////////////////////////////////////////////////////////////////////

rmsoscillator_t RMSOscillatorBeginSineWave(double hertz, double sampleRate)
{ return RMSOscillatorBegin(hertz, sampleRate, sineWave); }

rmsoscillator_t RMSOscillatorBeginTriangleWave(double hertz, double sampleRate)
{ return RMSOscillatorBegin(hertz, sampleRate, triangleWave); }

rmsoscillator_t RMSOscillatorBeginPseudoSineWave(double hertz, double sampleRate)
{ return RMSOscillatorBegin(hertz, sampleRate, pseudoSineWave); }

////////////////////////////////////////////////////////////////////////////////

void RMSOscillatorSetStep(rmsoscillator_t *oscPtr, double step)
{ oscPtr->Xstep = step; }

////////////////////////////////////////////////////////////////////////////////

double RMSOscillatorFetchSample(rmsoscillator_t *oscPtr)
{
	oscPtr->X += oscPtr->Xstep;
	if (oscPtr->X >= 1.0)
	{ oscPtr->X -= 2.0; }
	return oscPtr->functionPtr ? oscPtr->functionPtr(oscPtr->X) : oscPtr->X;
}

////////////////////////////////////////////////////////////////////////////////



