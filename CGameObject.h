//-------------------------------------------------------------------
//	CGameObject.h
//
//	Abstract base class for all game objects
//-------------------------------------------------------------------
#ifndef CGAME_OBJECT_H
#define CGAME_OBJECT_H

#include "ODEManager.h"
//#include "TextureManager.h"
#include "ode\ode.h"

#include <string>

class CGameObject
{

public:
	
	CGameObject();
	virtual ~CGameObject();

	int			ID;					//unique ID for all game objects
	
	virtual void			Update()=0;
	virtual void			Draw()=0;		
	virtual void			AddForce(double x, double y, double z)=0;
	virtual void			setPos(double x, double y, double z)=0;
	virtual void			setVel(double x, double y, double z)=0;
	virtual const double*	getPos();	
	virtual dBodyID			getBodyID();
	virtual void			setColor (double r, double g, double b);
	virtual void			setColor (double r, double g, double b, double a);
	virtual	const double*	getColor(){ return m_color; };
	virtual const double*	getSize() { return m_size; };
	virtual void			DisableGravity();
	virtual void			EnableGravity();
	virtual void			EnableBody();
	virtual void			DisableBody();

	virtual void			setTexture(char* fileName);
	virtual void			DestroyODEObject();
	virtual bool			isDynamic();

protected:
	dBodyID m_body;				// the body
	dGeomID m_geom;				// geometries representing this body
	double	m_position[3];		// position in world cordinates
	double	m_size[3];			// width/depth/height
	double	m_color[4];			// 4 value color
	//Texture*  m_texture;
	bool	m_dynamic;
	bool	m_odeDestroyed;
private:
	static int lastID;

};


#endif