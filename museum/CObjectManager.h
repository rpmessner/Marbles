//-------------------------------------------------------------------
//	CObjectManager
//
//	Manages all of our objects
//-------------------------------------------------------------------
#ifndef OBJECT_MANAGER_H
#define OBJECT_MANAGER_H

#include "CGameObject.h"
#include "Singleton.h"
#include "ObjectFactory.h"

#include <ode/ode.h>
#include <string>
#include <map>
#include <vector>

using std::vector;
using std::iterator;
using std::map;

typedef vector<CGameObject*> ObjectList;
typedef map<dBodyID, CGameObject*> ObjectIDMap;
typedef ObjectFactory<CGameObject *(), std::string> ObjFactory;
// here are our object types
static std::string Marble_Type = "marble type";
static std::string Tolley_Type = "tolley type";

class CObjectManager : public Singleton<CObjectManager>
{

public:

	CObjectManager();
	~CObjectManager();
	void AddObject (CGameObject*);
	void DestroyObjects();	//destroys ALL objects!

	void DrawObjects();
	void UpdateObjects();
	
	CGameObject* CreateObject  (std::string type);

	CGameObject* getObject(dBodyID id);

	bool	DynamicsDone();

private:
	ObjFactory  CGameObjectFactory;
	ObjectList	m_objectList;
	ObjectIDMap	m_objectIDMap;
	double		m_dynamicWaitTime;
	double		m_dynamicWaitLastTime;

};

#endif