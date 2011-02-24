#include "CMarble.h"
#include "CGameObject.h"
#include "CGLRender.h"

#include <ode/ode.h>
#include <gl/glut.h>
#include <stdlib.h>

CMarble::CMarble()
{	 
	m_radius=MARBLE_RADIUS;
	dMass m; 
	m_texture = -1;
	bool inPlay = true;


	//Create sphere	
	dMassSetSphere (&m,20.0f,m_radius/2);	
	m_geom = ODEManager::Instance().createSphere(m_radius);

	dGeomSetBody (m_geom,m_body);
    dBodySetMass (m_body,&m);	
	
	//m_numberTexture = 0;
	setPos(0.0f,0.0f,0.0f);	
	setColor(0.8f,0.8f,0.8f,1.0f);
}

CTolley::CTolley()
{
	m_radius=TOLLEY_RADIUS;
	dMass m;	
		
	//Create sphere	
	dMassSetSphere (&m,20.0f,m_radius/2);	
	m_geom = ODEManager::Instance().createSphere(m_radius);

	dGeomSetBody (m_geom,m_body);
    dBodySetMass (m_body,&m);	
	
	//m_numberTexture = 0;
	setPos(0.0f,0.0f,0.0f);	
	setColor(1.0f,1.0f,1.0f,1.0f);
}

CMarble::~CMarble()
{
	free(m_geom);
}

double 
CMarble::getRadius()
{
	return m_radius;
}

void 
CMarble::setRadius(double r) 
{
	m_radius = r;
	dMass m;	
	dMassSetSphere (&m,10.0f,m_radius);
    dBodySetMass (m_body,&m);
}
/*@todo
  add a new class for the tolley, or be able to alter the 
  dAccel value for tolley...
*/
void
CMarble::Update ()
{
	dReal dAccel = -1.0;
	dReal dAngAccel = -0.05;
	float dist = (m_lastPosition[0])*(m_lastPosition[0]) +
				 (m_lastPosition[2])*(m_lastPosition[2]);
	
	if (  dist > RING_RADIUS*RING_RADIUS ) {
		 dAccel = -3.0;
		 dAngAccel = -0.1;
		 m_inPlay = false;
		 m_color[1] = m_color[2] = 0;
	}
	
	m_lastPosition[0] = m_position[0];
	m_lastPosition[1] = m_position[1];
	m_lastPosition[2] = m_position[2];
	const dReal* pos = dBodyGetPosition(m_body);
	m_position[0] = pos[0];
	m_position[1] = pos[1];
	m_position[2] = pos[2];
	const dReal* vel = dBodyGetLinearVel(m_body);
	const dReal* omega   = dBodyGetAngularVel (m_body);
	if (m_position[1] <= m_radius) 
		dBodyAddTorque(m_body, dAngAccel*omega[0], dAngAccel*omega[1], dAngAccel*omega[2]);
	if (m_position[1] <= m_radius) 
		;//dBodyAddForce(m_body, vel[0]*dAccel, 0, vel[2]*dAccel);
}
double
CMarble::getVel()
{
	const dReal* vel = dBodyGetLinearVel(m_body);

	double val = vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2];

	return val;
}

// the tolley needs to slow down regardless of whether it's in the circle 
void
CTolley::Update ()
{
	dReal dAccel = -1.5;
	dReal dAngAccel = -0.5;
	float dist = (m_lastPosition[0])*(m_lastPosition[0]) +
				 (m_lastPosition[2])*(m_lastPosition[2]);
	
	if (  dist > RING_RADIUS*RING_RADIUS ) {
		 dAccel = -3.0;
		 dAngAccel = -0.3;
	}
	
	m_lastPosition[0] = m_position[0];
	m_lastPosition[1] = m_position[1];
	m_lastPosition[2] = m_position[2];
	const dReal* pos = dBodyGetPosition(m_body);
	m_position[0] = pos[0];
	m_position[1] = pos[1];
	m_position[2] = pos[2];
	const dReal* vel = dBodyGetLinearVel(m_body);
	const dReal* omega   = dBodyGetAngularVel (m_body);
	if (m_position[1] <= m_radius) 
		dBodyAddTorque(m_body, dAngAccel*omega[0], dAngAccel*omega[1], dAngAccel*omega[2]);
	if (m_position[1] <= m_radius) 
		dBodyAddForce(m_body, vel[0]*dAccel, 0, vel[2]*dAccel);
}

void 
CMarble::Draw ()
{
	CGLRender::Instance().setTexture(m_texture);
	CGLRender::Instance().setColorLight(m_color[0], m_color[1], m_color[2], m_color[3], 0.4);
	const dReal* pos = dGeomGetPosition(m_geom);  
	const dReal* R   = dGeomGetRotation(m_geom);
	CGLRender::Instance().drawSphere(pos, R, m_radius);
}

void 
CMarble::AddForce(double x, double y, double z)
{
	if(!m_odeDestroyed)
		dBodyAddForce(m_body, x, y, z);	
}
void 
CMarble::AddTorque(double x, double y, double z)
{
	if(!m_odeDestroyed)
		dBodyAddTorque(m_body, x, y, z);
}

void 
CMarble::setVel(double x, double y, double z)
{
	dBodySetLinearVel(m_body,x,y,z);
}

void 
CMarble::setPos(double x, double y, double z)
{
	m_position[0] = x;
	m_position[1] = y;
	m_position[2] = z;

	m_lastPosition[0] = x;
	m_lastPosition[1] = y;
	m_lastPosition[2] = z;

	if(!m_odeDestroyed)
		dBodySetPosition(m_body, x,y,z);	
}
