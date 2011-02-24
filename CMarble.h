#ifndef CMARBLE_H
#define CMARBLE_H

#include "CGameObject.h"

#include <windows.h>
#include <gl\gl.h>
#include <gl\glu.h>

#define MARBLE_RADIUS (0.5)
#define TOLLEY_RADIUS (0.75)
#define RING_RADIUS (20.0)

class CMarble : public CGameObject
{
public:
	CMarble();
	~CMarble();

	virtual void Update();
	virtual void Draw();
	virtual void AddForce(double x, double y, double z);
	virtual void AddTorque(double x, double y, double z);
	virtual double getVel();
	virtual void setVel(double x, double y, double z);
	virtual void setPos(double x, double y, double z);
	double getRadius();
	void setRadius(double r);
protected:
	GLuint m_texture;
	double m_radius;
	double m_lastPosition[3];
private:
	bool m_inPlay;
	static m_textureNumber;
	const char* m_textureNames;
	
};

class CTolley : public CMarble
{
public:
	CTolley();
	virtual void Update();
};

#endif