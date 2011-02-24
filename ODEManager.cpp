#include "ODEManager.h"

#include "CGame.h"
#include "CTimer.h"
#include "SoundManager.h"

#include <ode/ode.h>

ODEManager::ODEManager()
{
	m_world = dWorldCreate();
	m_space = dHashSpaceCreate(0);
	
	m_contactgroup = dJointGroupCreate(0);
	setGravity(0.0f,-9.8f,0.0f);
	dWorldSetCFM(m_world,1e-5);
	
	m_plane = dCreatePlane(m_space,0,1,0,0);
}

ODEManager::~ODEManager()
{

}

//-------------------------------------------------------
//	This is an ugly temp hack to get key presses
//-------------------------------------------------------
static void command (int cmd)
{
	//Game::Instance().onKeyPress(cmd);
}


void ODEManager::setViewPoint(double xyz[], double hpr[])
{    
	//dsSetViewpoint (xyz,hpr);
}

//-------------------------------------------------------------------
//	Sim Loop main loop!
//-------------------------------------------------------------------

void ODEManager::SimLoop(bool pause)
{
	if (!pause) {
		double deltaT = CTimer::Instance().getDeltaT();
		dSpaceCollide (m_space,0,&ODEManager::StaticCallback);
		dWorldStep (m_world,0.05);

		/* remove all contact joints */
		dJointGroupEmpty (m_contactgroup);
	}
}

//-------------------------------------------------------------------
//	Creates a new body inside our world, returns body ID
//-------------------------------------------------------------------

dBodyID ODEManager::createBody()
{
	return dBodyCreate(m_world);
}

//-------------------------------------------------------------------
//	Create a sphere, return the geomID
//-------------------------------------------------------------------

dGeomID ODEManager::createSphere(double radius)
{	
	return dCreateSphere(m_space,radius);    
}


//-----------------------------------------------------
//	Create plane, return geomID
//-----------------------------------------------------

dGeomID	ODEManager::createPlane(dReal a, dReal b, dReal c, dReal d)
{
	return dCreatePlane(m_space,a,b,c,d);
}

//-------------------------------------------------------
//	Create a box, return the geomID
//-------------------------------------------------------

dGeomID ODEManager::createBox(double length, double width, double height)
{
	return dCreateBox(m_space, length, width, height);
}


dGeomID ODEManager::createGeomTransform()
{
	return dCreateGeomTransform(m_space);
}
//-------------------------------------------------------------------
//	Call back function called when two bodies are near collision
//-------------------------------------------------------------------

void ODEManager::NearCallback (void *data, dGeomID o1, dGeomID o2)
{
	int i;
	// if (o1->body && o2->body) return;

	// exit without doing anything if the two bodies are connected by a joint
	
	dBodyID b1 = dGeomGetBody(o1);
	dBodyID b2 = dGeomGetBody(o2);
	if (b1 && b2 && dAreConnectedExcluding (b1,b2,dJointTypeContact)) return;
	if (o1 != m_plane && o2 != m_plane)
		CGame::Instance().CheckCollisions(b1, b2);
	dContact contact[MAX_CONTACTS];   // up to MAX_CONTACTS contacts per box-box
	for (i=0; i<MAX_CONTACTS; i++) {
		contact[i].surface.mode = dContactBounce | dContactApprox1; // | dContactSoftCFM;
		contact[i].surface.mu = dInfinity;
		contact[i].surface.mu2 = dInfinity;
		contact[i].surface.bounce = 0.75f;
		contact[i].surface.bounce_vel = 0.1;
		//contact[i].surface.soft_cfm = 0.01;
	}

	if (int numc = dCollide (o1,o2,MAX_CONTACTS,&contact[0].geom, sizeof(dContact))) 
	{   
		//if(CGame::Instance().onCollision(b1, b2)==true)
		
		dMatrix3 RI;
		dRSetIdentity (RI);
		const dReal ss[3] = {0.02,0.02,0.02};
		for (i=0; i<numc; i++) 
		{
			dJointID c = dJointCreateContact (m_world,m_contactgroup,contact+i);
			dJointAttach (c,b1,b2);			
		}
	}
}

//-----------------------------------------------------------------
//	Gravity
//-----------------------------------------------------------------

void ODEManager::setGravity(double x, double y, double z)
{
	m_gravity[0] = x;
	m_gravity[1] = y;
	m_gravity[2] = z;


	dWorldSetGravity(m_world,m_gravity[0],m_gravity[1],m_gravity[2]);
}

double* ODEManager::getGravity()
{
	return m_gravity;
}


