#include "CGLRender.h"
#include "CGame.h"

#include <windows.h>
#include <gl/gl.h>
#include <gl/glu.h>
#include <gl/glut.h>

CGLRender::CGLRender()
{
	m_width = 640;
	m_height = 480;
	active=TRUE;		// Window Active Flag Set To TRUE By Default
	fullscreen=TRUE;	// Fullscreen Flag Set To Fullscreen Mode By Default
	hDC=NULL;			// Private GDI Device Context
	hRC=NULL;			// Permanent Rendering Context
	hWnd=NULL;			// Holds Our Window Handle
	hInstance;
	m_light_ambient[0]	= 0.0f;
	m_light_ambient[1]	= 0.0f;
	m_light_ambient[2]  = 0.0f;
	m_light_ambient[3]  = 1.0f;
	
	m_light_diffuse[0]	= 1.0f;
	m_light_diffuse[1]	= 1.0f;
	m_light_diffuse[2]	= 1.0f;
	m_light_diffuse[3]	= 1.0f;
	
	m_light_specular[0]	= 1.0f;
	m_light_specular[1]	= 1.0f;
	m_light_specular[2]	= 1.0f;
	m_light_specular[3]	= 1.0f;
	
	m_lmodel_ambient[0]	= 0.5f;
	m_lmodel_ambient[1]	= 0.5f;
	m_lmodel_ambient[2]	= 0.5f;
	m_lmodel_ambient[3]	= 0.5f;
	
	m_mat_amb_diff[0]	= 0.2f;
	m_mat_amb_diff[1]	= 0.2f;
	m_mat_amb_diff[2]	= 0.2f;
	m_mat_amb_diff[3]	= 0.2f;
	
	m_mat_specular[0]	= 1.0f;
	m_mat_specular[1]	= 1.0f;
	m_mat_specular[2]	= 1.0f;
	m_mat_specular[3]	= 1.0f;
	
	m_mat_shininess[1]	= 2.0f;
	
	m_light_position0[0]	= 0.0f;
	m_light_position0[1]	= 10.0f;
	m_light_position0[2]	= 0.0f;
	m_light_position0[3]	= 1.0f;
}

CGLRender::CGLRender(int w, int h)
{
	m_width = w;
	m_height = h;
	active=TRUE;		// Window Active Flag Set To TRUE By Default
	fullscreen=TRUE;	// Fullscreen Flag Set To Fullscreen Mode By Default
	hDC=NULL;		// Private GDI Device Context
	hRC=NULL;		// Permanent Rendering Context
	hWnd=NULL;		// Holds Our Window Handle
	hInstance;	
}
CGLRender::~CGLRender()
{
	;
}

GLvoid CGLRender::ReSizeGLScene(GLsizei width, GLsizei height)		// Resize And Initialize The GL Window
{
	m_width = width;
	m_height = height;
	if (height==0)										// Prevent A Divide By Zero By
	{
		height=1;										// Making Height Equal One
	}

	glViewport(0,0,width,height);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

	// Calculate The Aspect Ratio Of The Window
	gluPerspective(45.0f,(GLfloat)width/(GLfloat)height,0.1f,100.0f);

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix
}

int CGLRender::InitGL(GLvoid)										// All Setup For OpenGL Goes Here
{
	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.5f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations
	glEnable(GL_TEXTURE_2D);
	glShadeModel (GL_SMOOTH);

	glLightfv(GL_LIGHT0, GL_AMBIENT, m_light_ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, m_light_diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, m_light_specular);
	glLightfv(GL_LIGHT0, GL_POSITION, m_light_position0);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, m_lmodel_ambient);
	glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, m_mat_amb_diff);
	glMaterialfv(GL_FRONT, GL_SPECULAR, m_mat_specular);
	glMaterialfv(GL_FRONT, GL_SHININESS, m_mat_shininess);
	//Enable Lighting
	glEnable(GL_COLOR_MATERIAL);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	return TRUE;										// Initialization Went OK
}

int CGLRender::StartGLScene(GLvoid)						// Here's Where We Do All The Drawing
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer
	glLoadIdentity();									// Reset The Current Modelview Matrix
	
	return TRUE;
}

int CGLRender::EndGLScene(GLvoid)
{
	SwapBuffers(hDC);	
	return TRUE;										// Everything Went OK
}

GLvoid CGLRender::KillGLWindow(GLvoid)					// Properly Kill The Window
{
	if (fullscreen)										// Are We In Fullscreen Mode?
	{
		ChangeDisplaySettings(NULL,0);					// If So Switch Back To The Desktop
		ShowCursor(TRUE);								// Show Mouse Pointer
	}

	if (hRC)											// Do We Have A Rendering Context?
	{
		if (!wglMakeCurrent(NULL,NULL))					// Are We Able To Release The DC And RC Contexts?
		{
			MessageBox(NULL,"Release Of DC And RC Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}

		if (!wglDeleteContext(hRC))						// Are We Able To Delete The RC?
		{
			MessageBox(NULL,"Release Rendering Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		}
		hRC=NULL;										// Set RC To NULL
	}

	if (hDC && !ReleaseDC(hWnd,hDC))					// Are We Able To Release The DC
	{
		MessageBox(NULL,"Release Device Context Failed.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hDC=NULL;										// Set DC To NULL
	}

	if (hWnd && !DestroyWindow(hWnd))					// Are We Able To Destroy The Window?
	{
		MessageBox(NULL,"Could Not Release hWnd.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hWnd=NULL;										// Set hWnd To NULL
	}

	if (!UnregisterClass("OpenGL",hInstance))			// Are We Able To Unregister Class
	{
		MessageBox(NULL,"Could Not Unregister Class.","SHUTDOWN ERROR",MB_OK | MB_ICONINFORMATION);
		hInstance=NULL;									// Set hInstance To NULL
	}
}

void
CGLRender::drawAim(double x, double z, double throb)
{
	glPushMatrix();
	glTranslatef(x,0,z);
	glDisable(GL_TEXTURE_2D);
	for (double i = 1.0; i > 0.0; i-=0.2) {
		glColor3d(1.0, 1.0, 1.0);
		glBegin(GL_LINE_LOOP);
		glLineWidth(4.0);
		
		for (double x = 1; x >= 0.0; x -= .02) {
			glVertex3f(i*cos(x*2.0*M_PI) , 0, i*sin(x*2.0*M_PI));
		}
		glEnd();

	}
	glEnable(GL_TEXTURE_2D);
	glPopMatrix();

}
void CGLRender::drawFloor()
{	
	//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear The Screen And The Depth Buffer
	//glLoadIdentity();									// Reset The matrix
	
		// 	  Position      View	   Up Vector
	//gluLookAt(6, 6, 6,     0, 0, 0,     0, 1, 0);		// This determines where the camera's position and view is
	glPushMatrix();
	glRotatef(90, 1, 0,0 );
	glColor3f(1.0,1.0,1.0);
	glScalef(30,30,30);

	glBindTexture(GL_TEXTURE_2D, m_texture[0]);

	// Display a quad texture to the screen
	glBegin(GL_QUADS);

		glTexCoord2f(0.0f, 1.0f);
		glVertex3f(-1, 1, 0);

		// Display the bottom left vertice
		glTexCoord2f(0.0f, 0.0f);
		glVertex3f(-1, -1, 0);

		// Display the bottom right vertice
		glTexCoord2f(1.0f, 0.0f);
		glVertex3f(1, -1, 0);

		// Display the top right vertice
		glTexCoord2f(1.0f, 1.0f);
		glVertex3f(1, 1, 0);

	glEnd();											// Stop drawing QUADS
	glPopMatrix();

}
void CGLRender::drawGrid()
{
	// Turn the lines GREEN
	glColor3ub(0, 255, 0);
	glLineWidth(4.0);
	// Draw a 1x1 grid along the X and Z axis'
	for(double i = -50; i <= 50; i += 1)
	{
		// Start drawing some lines
		glBegin(GL_LINES);

			// Do the horizontal lines (along the X)
			glVertex3d(-50, 0, i);
			glVertex3d(50, 0, i);

			// Do the vertical lines (along the Z)
			glVertex3d(i, 0, -50);
			glVertex3d(i, 0, 50);

		// Stop drawing lines
		glEnd();
	}
}

void CGLRender::drawSphere(const double pos[3], const double R[12], double radius)
{
	setUpDrawingMode();
	glBindTexture(GL_TEXTURE_2D, m_texture[1]);
	glEnable (GL_NORMALIZE);
	glShadeModel (GL_SMOOTH);
	glPushMatrix();
	setTransform (pos,R);
	glScaled (radius,radius,radius);
	drawSphere();
	glPopMatrix();
	glDisable (GL_NORMALIZE); 
}

void CGLRender::drawSphere()
{
	GLUquadricObj *quadratic;				
	quadratic=gluNewQuadric();			
	
	gluQuadricNormals(quadratic, GLU_SMOOTH);	
	gluQuadricTexture(quadratic, GL_TRUE);		

	gluSphere(quadratic,1.0f,32,32);		
}

void CGLRender::setViewpoint ( double posx, double posy, double posz,
							   double eyex, double eyey, double eyez,
							   double upx,  double upy,  double upz )
{
	gluLookAt( posx, posy, posz,
			   eyex, eyey, eyez,
			   upx,  upy,  upz );
}

void CGLRender::setUpDrawingMode()
{	
	setColorLight (m_color[0],m_color[1],m_color[2],m_color[3], m_mat_shininess[1]);			
}

void CGLRender::setTexture(GLuint tex) 
{
}

void CGLRender::CreateTexture(UINT textureArray[], LPSTR strFileName, int textureID)
{
	AUX_RGBImageRec *pBitmap = NULL;
	
	if(!strFileName)									// Return from the function if no file name was passed in
		return;
	
	pBitmap = auxDIBImageLoad(strFileName);				// Load the bitmap and store the data
	
	if(pBitmap == NULL)									// If we can't load the file, quit!
		exit(0);

	glGenTextures(1, &m_texture[textureID]);

	glBindTexture(GL_TEXTURE_2D, m_texture[textureID]);

	gluBuild2DMipmaps(GL_TEXTURE_2D, 3, pBitmap->sizeX, pBitmap->sizeY, GL_RGB, GL_UNSIGNED_BYTE, pBitmap->data);
		
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR_MIPMAP_LINEAR);

	// Now we need to free the bitmap data that we loaded since openGL stored it as a texture

	if (pBitmap)										// If we loaded the bitmap
	{
		if (pBitmap->data)								// If there is texture data
		{
			free(pBitmap->data);						// Free the texture data, we don't need it anymore
		}

		free(pBitmap);									// Free the bitmap structure
	}
}
void CGLRender::setColorLight(double r, double g, double b, double alpha, double shine)
{
	m_light_ambient[0] = r*0.3f;
	m_light_ambient[1] = g*0.3f;
	m_light_ambient[2] = b*0.3f;
	m_light_ambient[3] = alpha;
	m_light_diffuse[0] = r*0.7f;
	m_light_diffuse[1] = g*0.7f;
	m_light_diffuse[2] = b*0.7f;
	m_light_diffuse[3] = alpha;
	m_light_specular[0] = r*0.2f;
	m_light_specular[1] = g*0.2f;
	m_light_specular[2] = b*0.2f;
	m_light_specular[3] = alpha;
	m_mat_shininess[1] = shine;
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, m_light_ambient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, m_light_diffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, m_light_specular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, m_mat_shininess[1]);

	m_color[0] = r;
	m_color[1] = g;
	m_color[2] = b;
	m_color[3] = alpha;

	glColor4f(r, g, b, alpha);
}

void CGLRender::setTransform (const double pos[3], const double R[12])
{
  GLfloat matrix[16];
  matrix[0]	=	(GLfloat)R[0];
  matrix[1]	=	(GLfloat)R[4];
  matrix[2]	=	(GLfloat)R[8];
  matrix[3]	=	(GLfloat)0;
  matrix[4]	=	(GLfloat)R[1];
  matrix[5]	=	(GLfloat)R[5];
  matrix[6]	=	(GLfloat)R[9];
  matrix[7]	=	(GLfloat)0;
  matrix[8]	=	(GLfloat)R[2];
  matrix[9]	=	(GLfloat)R[6];
  matrix[10]=	(GLfloat)R[10];
  matrix[11]=	(GLfloat)0;
  matrix[12]=	(GLfloat)pos[0];
  matrix[13]=	(GLfloat)pos[1];
  matrix[14]=	(GLfloat)pos[2];
  matrix[15]=	(GLfloat)1;
  glMultMatrixf (matrix);
}
/*	This Code Creates Our OpenGL Window.  Parameters Are:					*
 *	title			- Title To Appear At The Top Of The Window				*
 *	width			- Width Of The GL Window Or Fullscreen Mode				*
 *	height			- Height Of The GL Window Or Fullscreen Mode			*
 *	bits			- Number Of Bits To Use For Color (8/16/24/32)			*
 *	fullscreenflag	- Use Fullscreen Mode (TRUE) Or Windowed Mode (FALSE)	*/
 
BOOL CGLRender::CreateGLWindow(char* title, int width, int height, int bits, bool fullscreenflag)
{
	GLuint		PixelFormat;			// Holds The Results After Searching For A Match
	WNDCLASS	wc;						// Windows Class Structure
	DWORD		dwExStyle;				// Window Extended Style
	DWORD		dwStyle;				// Window Style
	RECT		WindowRect;				// Grabs Rectangle Upper Left / Lower Right Values
	WindowRect.left=(long)0;			// Set Left Value To 0
	WindowRect.right=(long)width;		// Set Right Value To Requested Width
	WindowRect.top=(long)0;				// Set Top Value To 0
	WindowRect.bottom=(long)height;		// Set Bottom Value To Requested Height

	fullscreen=fullscreenflag;			// Set The Global Fullscreen Flag

	hInstance			= GetModuleHandle(NULL);				// Grab An Instance For Our Window
	wc.style			= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;	// Redraw On Size, And Own DC For Window.
	wc.lpfnWndProc		= (WNDPROC) WndProc;					// WndProc Handles Messages
	wc.cbClsExtra		= 0;									// No Extra Window Data
	wc.cbWndExtra		= 0;									// No Extra Window Data
	wc.hInstance		= hInstance;							// Set The Instance
	wc.hIcon			= LoadIcon(NULL, IDI_WINLOGO);			// Load The Default Icon
	wc.hCursor			= LoadCursor(NULL, IDC_ARROW);			// Load The Arrow Pointer
	wc.hbrBackground	= NULL;									// No Background Required For GL
	wc.lpszMenuName		= NULL;									// We Don't Want A Menu
	wc.lpszClassName	= "OpenGL";								// Set The Class Name

	if (!RegisterClass(&wc))									// Attempt To Register The Window Class
	{
		MessageBox(NULL,"Failed To Register The Window Class.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;											// Return FALSE
	}
	
	if (fullscreen)												// Attempt Fullscreen Mode?
	{
		DEVMODE dmScreenSettings;								// Device Mode
		memset(&dmScreenSettings,0,sizeof(dmScreenSettings));	// Makes Sure Memory's Cleared
		dmScreenSettings.dmSize=sizeof(dmScreenSettings);		// Size Of The Devmode Structure
		dmScreenSettings.dmPelsWidth	= width;				// Selected Screen Width
		dmScreenSettings.dmPelsHeight	= height;				// Selected Screen Height
		dmScreenSettings.dmBitsPerPel	= bits;					// Selected Bits Per Pixel
		dmScreenSettings.dmFields=DM_BITSPERPEL|DM_PELSWIDTH|DM_PELSHEIGHT;

		// Try To Set Selected Mode And Get Results.  NOTE: CDS_FULLSCREEN Gets Rid Of Start Bar.
		if (ChangeDisplaySettings(&dmScreenSettings,CDS_FULLSCREEN)!=DISP_CHANGE_SUCCESSFUL)
		{
			// If The Mode Fails, Offer Two Options.  Quit Or Use Windowed Mode.
			if (MessageBox(NULL,"The Requested Fullscreen Mode Is Not Supported By\nYour Video Card. Use Windowed Mode Instead?","NeHe GL",MB_YESNO|MB_ICONEXCLAMATION)==IDYES)
			{
				fullscreen=FALSE;		// Windowed Mode Selected.  Fullscreen = FALSE
			}
			else
			{
				// Pop Up A Message Box Letting User Know The Program Is Closing.
				MessageBox(NULL,"Program Will Now Close.","ERROR",MB_OK|MB_ICONSTOP);
				return FALSE;									// Return FALSE
			}
		}
	}

	if (fullscreen)												// Are We Still In Fullscreen Mode?
	{
		dwExStyle=WS_EX_APPWINDOW;								// Window Extended Style
		dwStyle=WS_POPUP;										// Windows Style
		ShowCursor(FALSE);										// Hide Mouse Pointer
	}
	else
	{
		dwExStyle=WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;			// Window Extended Style
		dwStyle=WS_OVERLAPPEDWINDOW;							// Windows Style
	}

	AdjustWindowRectEx(&WindowRect, dwStyle, FALSE, dwExStyle);		// Adjust Window To True Requested Size

	// Create The Window
	if (!(hWnd=CreateWindowEx(	dwExStyle,							// Extended Style For The Window
								"OpenGL",							// Class Name
								title,								// Window Title
								dwStyle |							// Defined Window Style
								WS_CLIPSIBLINGS |					// Required Window Style
								WS_CLIPCHILDREN,					// Required Window Style
								0, 0,								// Window Position
								WindowRect.right-WindowRect.left,	// Calculate Window Width
								WindowRect.bottom-WindowRect.top,	// Calculate Window Height
								NULL,								// No Parent Window
								NULL,								// No Menu
								hInstance,							// Instance
								NULL)))								// Dont Pass Anything To WM_CREATE
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Window Creation Error.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	static	PIXELFORMATDESCRIPTOR pfd=				// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),				// Size Of This Pixel Format Descriptor
		1,											// Version Number
		PFD_DRAW_TO_WINDOW |						// Format Must Support Window
		PFD_SUPPORT_OPENGL |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		bits,										// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,											// No Alpha Buffer
		0,											// Shift Bit Ignored
		0,											// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		16,											// 16Bit Z-Buffer (Depth Buffer)  
		0,											// No Stencil Buffer
		0,											// No Auxiliary Buffer
		PFD_MAIN_PLANE,								// Main Drawing Layer
		0,											// Reserved
		0, 0, 0										// Layer Masks Ignored
	};
	
	if (!(hDC=GetDC(hWnd)))							// Did We Get A Device Context?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Create A GL Device Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if (!(PixelFormat=ChoosePixelFormat(hDC,&pfd)))	// Did Windows Find A Matching Pixel Format?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Find A Suitable PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if(!SetPixelFormat(hDC,PixelFormat,&pfd))		// Are We Able To Set The Pixel Format?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Set The PixelFormat.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if (!(hRC=wglCreateContext(hDC)))				// Are We Able To Get A Rendering Context?
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Create A GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	if(!wglMakeCurrent(hDC,hRC))					// Try To Activate The Rendering Context
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Can't Activate The GL Rendering Context.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}

	ShowWindow(hWnd,SW_SHOW);						// Show The Window
	SetForegroundWindow(hWnd);						// Slightly Higher Priority
	SetFocus(hWnd);									// Sets Keyboard Focus To The Window
	ReSizeGLScene(width, height);					// Set Up Our Perspective GL Screen

	if (!InitGL())									// Initialize Our Newly Created GL Window
	{
		KillGLWindow();								// Reset The Display
		MessageBox(NULL,"Initialization Failed.","ERROR",MB_OK|MB_ICONEXCLAMATION);
		return FALSE;								// Return FALSE
	}
	
	CreateTexture(m_texture, "textures/floor.bmp", 0);
	CreateTexture(m_texture, "textures/marble1.bmp", 1);
	return TRUE;									// Success
}

/*
 WndProc - the callback func for windows message processing
*/
LRESULT CALLBACK WndProc(	HWND	hWnd,			// Handle For This Window
							UINT	uMsg,			// Message For This Window
							WPARAM	wParam,			// Additional Message Information
							LPARAM	lParam)			// Additional Message Information
{
	switch (uMsg)									// Check For Windows Messages
	{
		case WM_ACTIVATE:							// Watch For Window Activate Message
		{
			if (!HIWORD(wParam))					// Check Minimization State
			{
				CGLRender::Instance().setActive(true);						// Program Is Active
			}
			else
			{
				CGLRender::Instance().setActive(false);						// Program Is No Longer Active
			}

			return 0;								// Return To The Message Loop
		}

		case WM_SYSCOMMAND:							// Intercept System Commands
		{
			switch (wParam)							// Check System Calls
			{
				case SC_SCREENSAVE:					// Screensaver Trying To Start?
				case SC_MONITORPOWER:				// Monitor Trying To Enter Powersave?
				return 0;							// Prevent From Happening
			}
			break;									// Exit
		}

		case WM_CLOSE:								// Did We Receive A Close Message?
		{
			PostQuitMessage(0);						// Send A Quit Message
			return 0;								// Jump Back
		}

		case WM_SIZE:								// Resize The OpenGL Window
		{
			CGLRender::Instance().ReSizeGLScene(LOWORD(lParam),HIWORD(lParam));  // LoWord=Width, HiWord=Height
			return 0;								// Jump Back
		}
	}

	// Pass All Unhandled Messages To DefWindowProc
	return DefWindowProc(hWnd,uMsg,wParam,lParam);
}
