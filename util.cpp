
#include <cmath>
#include "util.h"

float dotProd(const float *a, const float *b)
{ 
	return ((a)[0]*(b)[0] + (a)[1]*(b)[1] + (a)[2]*(b)[2]); 
}


void normV3 (float v[3])
{
  float len = v[0]*v[0] + v[1]*v[1] + v[2]*v[2];
  if (len <= 0.0f) {
    v[0] = 1;
    v[1] = 0;
    v[2] = 0;
  }
  else {
    len = 1.0f / (float)sqrt(len);
    v[0] *= len;
    v[1] *= len;
    v[2] *= len;
  }
}

float smooth(float from, float to, float &vel, float delta, float smoothTime)
{		

	float omega = 2.0f / smoothTime;
	float x = omega * delta;
	float exp = 1.0f/(1.0f + x + 0.48f * x * x + 0.235f * x * x * x);
	float change = from - to;
	float temp = (vel + omega*change) * delta;
	vel = (vel - omega * temp) * exp;
	return to + (change + temp) * exp;

}
