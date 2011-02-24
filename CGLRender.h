#ifndef GLRENDER_H
#define GLRENDER_H

#include "Singleton.h"
#include "CVector3.h"

#include <windows.h>
#include <gl/gl.h>
#include <gl/glu.h>
#include <gl/glaux.h>

LRESULT	CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);

#define my_cos(n) cosTable[(int)(n*100)]
#define my_sin(n) sinTable[(int)(n*100)]
#define MAX_TEXTURES 10
class CGLRender : public Singleton<CGLRender>
{

public:
	CGLRender();
	CGLRender(int,int);
	~CGLRender();
	
	BOOL CreateGLWindow (char* title, int width, int height, int bits, bool fullscreenflag);
	GLvoid KillGLWindow (GLvoid);
	GLvoid ReSizeGLScene (GLsizei width, GLsizei height);
	int InitGL (GLvoid);
	
	int StartGLScene (GLvoid);	
	int EndGLScene (GLvoid);
	
	void toggleFullscreen () { fullscreen = !fullscreen; }
	void toggleTextures () { m_drawTexture = !m_drawTexture; }
	
	void setActive (bool newval) { active = newval; }
	bool getActive () { return active; }
	
	void setViewpoint( double, double, double, double, double, double, double, double, double );
	void setTransform (const double pos[3], const double R[12]);
	
	void setColorLight(double r, double g, double b, double alpha, double shine);
	void setColor (double r, double g, double b);
	void setTexture(GLuint tex);

	void drawSphere();
	void drawSphere(const double pos[3], const double R[12], double radius);
	void drawAim(double,double,double);
	void drawFloor();
	void drawGrid();

	int getHeight() { return m_height; }
	int getWidth () { return m_width; }

	HDC getHDC () { return hDC; }

private:
	void CreateTexture(UINT textureArray[], LPSTR strFileName, int textureID);

	int		m_width;
	int		m_height;
	double	m_color[4];
	double sinTable[104];
	double cosTable[104];
	// light and material properties here, so I have
	// the option of changing them between objects
	GLfloat m_light_ambient[4];
	GLfloat m_light_diffuse[4];
	GLfloat m_light_specular[4];
	GLfloat m_lmodel_ambient[4];
	GLfloat m_mat_amb_diff[4];
	GLfloat m_mat_specular[4];
	GLfloat m_mat_shininess[1];
	GLfloat m_light_position0[4]; 
	
	bool	active;		// Window Active Flag Set To TRUE By Default
	bool	fullscreen;	// Fullscreen Flag Set To Fullscreen Mode By Default
	
	bool	m_drawTexture; // whether we're drawing textures with primitives or not
	UINT	m_texture[MAX_TEXTURES];
	double  m_currentTextureScale;
	void setUpDrawingMode();
	HDC			hDC;		// Private GDI Device Context
	HGLRC		hRC;		// Permanent Rendering Context
	HWND		hWnd;		// Holds Our Window Handle
	HINSTANCE	hInstance;		// Holds The Instance Of The Application	
};



#endif