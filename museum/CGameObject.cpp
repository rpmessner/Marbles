#include "CGameObject.h"
#include <ode/ode.h>
#include "CGame.h"
#include <string>

CGameObject::CGameObject()
{
	m_body = ODEManager::Instance().createBody(); 
	m_dynamic = true;
	//m_texture=0;
	m_odeDestroyed = false;
}

CGameObject::~CGameObject()
{	
	//destroyODEObject();
}

bool
CGameObject::isDynamic()
{
	return m_dynamic;
}

const double* CGameObject::getPos()
{ 
	return dBodyGetPosition (m_body); 
}
	
dBodyID CGameObject::getBodyID()
{ 
	return m_body;
}
	
void CGameObject::setColor(double r, double g, double b, double a)
{
	m_color[0] = r;
	m_color[1] = g;
	m_color[2] = b;
	m_color[3] = a;
}

void CGameObject::setColor(double r, double g, double b)
{
	m_color[0] = r;
	m_color[1] = g;
	m_color[2] = b;
}

void CGameObject::DisableGravity()
{
	dBodySetGravityMode(m_body,0);
}

void CGameObject::EnableGravity()
{
	dBodySetGravityMode(m_body, 1); 
}

void CGameObject::setTexture(char* fileName)
{/*
	//lets see if it ends with .png, else just call the bitmap loaded
	int offset = strlen(fileName) - strlen(".png");
	assert(offset > 0);
	if( strcmp(fileName + offset, ".png") == 0)
	{
		m_texture = TextureManager::Instance().getTextureJPEG(fileName);
	}
	else
	{
		m_texture =  TextureManager::Instance().getTextureBMP(fileName, NormalTexture);
	}*/
}

void CGameObject::DisableBody()
{
	m_dynamic=false;
	dBodyDisable(m_body);
}

void CGameObject::EnableBody()
{
	m_dynamic=true;
	dBodyEnable(m_body);
}

void CGameObject::DestroyODEObject()
{
	if(!m_odeDestroyed)
	{
		m_odeDestroyed=true;
		dGeomDestroy(m_geom);
		dBodyDestroy(m_body);
	}
}