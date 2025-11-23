#include "CObjectManager.h"
#include "CGameObject.h"
#include "CMarble.h"
#include "ObjectFactory.h"
#include "CTimer.h"

#include <cassert>
#include <windows.h>

#define DYNAMICS_WAIT (1.0)

CObjectManager::CObjectManager()
{
	m_objectList.clear();
	if (!CGameObjectFactory.Register<CMarble>(Marble_Type)) {
		MessageBox(NULL,"Failed To Register The Object Class in ObjectFactory","ERROR",MB_OK|MB_ICONEXCLAMATION);
	}
	if (!CGameObjectFactory.Register<CTolley>(Tolley_Type)) {
		MessageBox(NULL,"Failed To Register The Object Class in ObjectFactory","ERROR",MB_OK|MB_ICONEXCLAMATION);
	}
	CObjectManager::m_dynamicWaitLastTime = 0;
	CObjectManager::m_dynamicWaitTime = 0;
}

CObjectManager::~CObjectManager()
{
	//assume objects have been deleted
	m_objectList.clear();
}

//-------------------------------------------------------------------
//	Create Object
//-------------------------------------------------------------------
void
CObjectManager::AddObject(CGameObject* in)
{
	m_objectList.push_back(in);
	m_objectIDMap[in->getBodyID()] = in;
}

CGameObject* CObjectManager::CreateObject  (std::string type)
{
	CGameObject* obj;
	if (( obj = CGameObjectFactory.Create(type)) == 0)
		throw "CGameObjectFactory.Create returned 0";
	
	m_objectIDMap[obj->getBodyID()] = obj;
	m_objectList.push_back(obj);
	return obj;
}

//-------------------------------------------------------------------
//	Draw all objects
//-------------------------------------------------------------------

void CObjectManager::DrawObjects()
{
	ObjectList::iterator i;
	for(i = m_objectList.begin(); i != m_objectList.end(); i++)
	{
		(*i)->Draw();
	}
}


//-----------------------------------------------------------------
//	Destroys all objects
//-----------------------------------------------------------------

void CObjectManager::DestroyObjects()
{
	int size = m_objectList.size();
	for(int i = 0; i < size; i++)
	{
		CGameObject* curr = m_objectList[i];
		curr->DestroyODEObject();
		delete curr;
	}
	
	m_objectList.clear();
}

//-------------------------------------------------------------------
//	Update all objects
//-------------------------------------------------------------------

void CObjectManager::UpdateObjects()
{
	ObjectList::iterator i=0;
	for(i = m_objectList.begin(); i != m_objectList.end(); i++)
	{
		(*i)->Update();
	}	
}


//----------------------------------------------------------
//	Looks up an object based on its ODE id
//----------------------------------------------------------
CGameObject* 
CObjectManager::getObject(dBodyID id)
{
	return m_objectIDMap[id];
}

//----------------------------------------------------------
//	Checks to see if all of our objects have stopped moving
//----------------------------------------------------------
bool 
CObjectManager::DynamicsDone()
{
	
	bool retval = true;
	int size = m_objectList.size();
	for(int i = 0; i < size; i++) {
		if (!m_objectList[i]->isDynamic()) continue;
		dBodyID curr = m_objectList[i]->getBodyID();
		const dReal* vel = dBodyGetLinearVel(curr);
		const dReal* tor = dBodyGetAngularVel(curr);
		if ((vel[0] <= 0.1 && vel[0] >= -0.1 )&&
			(vel[1] <= 0.1 && vel[1] >= -0.1 )&& 
			(vel[2] <= 0.1 && vel[2] >= -0.1 ))
			;
		else retval = false;
	}
	m_dynamicWaitLastTime = 0;
	m_dynamicWaitTime = 0;

	return retval;
}
