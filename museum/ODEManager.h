#ifndef ODE_MANAGER_H
#define ODE_MANAGER_H


#define GPB 6			//geometries per body
#define MAX_CONTACTS 6	// maximum number of contact points per body

#include "singleton.h"

#include <ode/ode.h>

class ODEManager: public Singleton<ODEManager>
{

public:

	ODEManager();
	~ODEManager();

	void SimLoop(bool pause);

	//  Have to have a static member for a callback, but 
	//  I don't want to make all my member data static (we're a singleton anyways)
	void NearCallback (void *data, dGeomID o1, dGeomID o2);
	static void StaticCallback(void* data, dGeomID o1, dGeomID o2)
	{ 
		ODEManager::Instance().NearCallback(data,o1,o2);
	}

	/*Wrapper ODE functions */
	dBodyID		createBody();
	dGeomID		createSphere(double radius);
	dGeomID		createBox(double length, double width, double height);
	dGeomID		createGeomTransform();
	dGeomID		createPlane(dReal a, dReal b, dReal c, dReal d); 

	double*		getGravity();
	void		setGravity(double x, double y, double z);

	/*Draw Stuff Methods - these are only temporary until we write our own renderer*/
	static void setViewPoint(double xyz[3], double hpr[3]);
private:
	dGeomID			m_plane;
	dWorldID		m_world;
	dSpaceID		m_space;
	dJointGroupID	m_contactgroup;
	double			m_gravity[3];
};


#endif