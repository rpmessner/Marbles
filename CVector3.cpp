#include <math.h>

#include "CVector3.h"

void CVector3::Cross(CVector3 vVector1, CVector3 vVector2)
{
	// Calculate the cross product with the non communitive equation
	x = ((vVector1.y * vVector2.z) - (vVector1.z * vVector2.y));
	y = ((vVector1.z * vVector2.x) - (vVector1.x * vVector2.z));
	z = ((vVector1.x * vVector2.y) - (vVector1.y * vVector2.x));
									 
}

double CVector3::Magnitude()
{
	return (double)sqrt( (x * x) + 
						(y * y) + 
						(z * z) );
}

void CVector3::Normalize()
{
	double mag = Magnitude();
	x /= mag;
	y /= mag;
	z /= mag;
}
double CVector3::operator[] (int i) 
{	
	if(i == 0) return x;
	if(i == 1) return y;
	if(i == 2) return z;
	return 0; 
}
// A default constructor
CVector3::CVector3() 
{
	initialized = false;
}

// This is our constructor that allows us to initialize our data upon creating an instance
CVector3::CVector3(double X, double Y, double Z) 
{ 
	x = X; y = Y; z = Z;
	initialized = true;
}

// Here we overload the + operator so we can add vectors together 
CVector3 
CVector3::operator+(CVector3 vVector)
{
	// Return the added vectors result.
	return CVector3(vVector.x + x, vVector.y + y, vVector.z + z);
}

// Here we overload the - operator so we can subtract vectors 
CVector3 
CVector3::operator-(CVector3 vVector)
{
	// Return the subtracted vectors result
	return CVector3(x - vVector.x, y - vVector.y, z - vVector.z);
}

// Here we overload the * operator so we can multiply by scalars
CVector3 
CVector3::operator*(double num)
{
	// Return the scaled vector
	return CVector3(x * num, y * num, z * num);
}

// Here we overload the / operator so we can divide by a scalar
CVector3 
CVector3::operator/(double num)
{
	// Return the scale vector
	return CVector3(x / num, y / num, z / num);
}

CVector3 
CVector3::operator= (CVector3 in) 
{ 
	x = in.x; 
	y = in.y; 
	z = in.z; 
	return *this;
}

void
CVector3::set(double xp, double yp, double zp)
{
	this->x = xp;
	this->y = yp;
	this->z = zp;
}
