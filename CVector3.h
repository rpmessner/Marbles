#ifndef CVECTOR3_H
#define CVECTOR3_H

class CVector3
{
public:
	
	// A default constructor
	CVector3();
	
	// This is our constructor that allows us to initialize our data upon creating an instance
	CVector3(double X, double Y, double Z);

	// Here we overload the + operator so we can add vectors together 
	CVector3 operator+(CVector3 vVector);
	
	// Here we overload the - operator so we can subtract vectors 
	CVector3 operator-(CVector3 vVector);
	
	// Here we overload the * operator so we can multiply by scalars
	CVector3 operator*(double num);

	// Here we overload the / operator so we can divide by a scalar
	CVector3 operator/(double num);
	
	CVector3 operator= (CVector3 in);
	double operator[] (int i);
	void CVector3::set (double,double,double);
	void Cross(CVector3 vVector1, CVector3 vVector2);

	double Magnitude();

	void Normalize();

	double x, y, z;
	bool initialized;
};



#endif