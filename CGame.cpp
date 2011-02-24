#include "CGame.h"
#include "CGLRender.h"
#include "CObjectManager.h"
#include "CMarble.h"
#include "CInputManager.h"

#include <windows.h>
#include <gl\glut.h>
#include <stdio.h>
#include <cmath>

#define NUM_MARBLES 25
#define LEFT_MB		0
#define RIGHT_MB	2

CGame::CGame()
{	
	CMessage* message = new CMessage();
	message->text = "Dude is on";
	message->xpos = 0;
	message->ypos = 0;
	m_messageList.push_back(message);
	int time = GetTickCount();
	srand(time);
	sprintf(m_windowTitle, "Marbles");
	for(int i=0;i<256;i++) {
		m_keys[i]=false;
	}
	m_throbber = 0;
	m_throbIncrSign = 1;
	m_pause = 0;
	m_viewInterp = 0;
	CCamera::Instance().LookAt( 40, 20, 40, 0, 0, 0, 0, 1, 0 );
	m_gameState = GS_LoadLevel;
	m_tolleyPos.set(-20, 0, 50);
	m_aimPos.set(0,0,0);
	m_p1Tolley = new CTolley;
	m_objectManager.AddObject(m_p1Tolley);
	m_marbleList.push_back(m_p1Tolley);
	m_p1Tolley->setPos(m_tolleyPos.x, 1, m_tolleyPos.z);
	m_soundManager.init();
	//m_soundManager.startMusic();
	//m_p1Tolley->DisableBody();
}

CGame::~CGame()
{
	;
}

//========================================================================================
//		CreateMarbles(int number) creates number amount of marbles and arranges them in 
//			a grid at the origin
//========================================================================================
bool
CGame::CreateMarbles(int number)
{
	CMarble* temp = NULL;
	for (int i = 0; i < number; i++)
		m_marbleList.push_back((CMarble*)m_objectManager.CreateObject(Marble_Type));
	
	double x = m_marbleList[1]->getRadius()*2;

	int cols = (int)sqrt((double)number)+1;
	int z = 0;
	for (int i = 0; i < cols; i++) 
		for (int j = 0; j < cols; j++) {
			m_marbleList[z++]->setPos((cols/2-i)*x, x/2, (cols/2-j)*x);
			if (z >= number) return true;
		}

	return true;
}

WPARAM
CGame::Start()
{
	m_quit = false;							// Bool Variable To Exit Loop
	bool fullscreen = false;

	// Create Our OpenGL Window
	if (!CGLRender::Instance().CreateGLWindow(m_windowTitle,1024,768,32,fullscreen))
	{
		return 0;									// Quit If Window Was Not Created
	}

	while(!m_quit)									// Loop That Runs While done=FALSE
	{
		
		if (CInputManager::Instance().CheckInput())
			;
		else {
			// Draw The Scene.  Watch For ESC Key And Quit Messages From DrawGLScene()
			if (CGLRender::Instance().getActive())						// Program Active?
			{
				CGLRender::Instance().StartGLScene();					// Draw The Scene
				MainLoop();
				//CGLRender::Instance().drawFloor();
				CGLRender::Instance().EndGLScene();	
				
			} if (CInputManager::Instance().KeyState(VK_F1)) {
				CInputManager::Instance().KeyUp(VK_F1);
				CGLRender::Instance().KillGLWindow();						// Kill Our Current Window
				fullscreen=!fullscreen;									// Toggle Fullscreen / Windowed Mode
				
				// Recreate Our OpenGL Window
				if (!CGLRender::Instance().CreateGLWindow(m_windowTitle,1024,768,32,fullscreen))
				{
					return 0;						// Quit If Window Was Not Created
				}
			}
		}
	}

	// Shutdown
	CGLRender::Instance().KillGLWindow();			// Kill The Window
	return 0;							// Exit The Program
}

void
CGame::MainLoop ()
{
	if (CInputManager::Instance().KeyState(VK_F2)) SoundManager::Instance().startMusic();
	if (CInputManager::Instance().KeyState(VK_F3)) SoundManager::Instance().stopMusic();
	int width = CGLRender::Instance().getWidth() >> 1;
	int height = CGLRender::Instance().getHeight() >> 1;
	if (m_gameState == GS_Menu) {
		;
	} else if (m_gameState == GS_LoadLevel) {
		CreateMarbles(NUM_MARBLES);
		m_gameState = GS_DynamicsSettle;
	} else {
		m_tolleyForward = m_tolleyPos-m_aimPos;
		m_tolleyForward.y = 0;
		m_tolleyForward.Normalize();

		CVector3 up(0, 1, 0);
		m_tolleyStrafe.Cross(m_tolleyForward, up);
		m_tolleyStrafe.Normalize();

		CTimer::Instance().FrameUpdate();
		m_deltaT = CTimer::Instance().getDeltaT();
		
		if (m_throbber < 0.0 || m_throbber > 1.0) m_throbIncrSign = -m_throbIncrSign;
		m_throbber += m_deltaT*m_throbIncrSign;

		ODEManager::Instance().SimLoop(m_pause);
		if (m_gameState == GS_DynamicsSettle) 
		{	
			interpView();

			if (CObjectManager::Instance().DynamicsDone())
				m_gameState = GS_AimShot;
			
		} 
		else if (m_gameState == GS_AimShot) 
		{

			double speed = m_deltaT*5;
			if (!CObjectManager::Instance().DynamicsDone()) {
				m_gameState = GS_DynamicsSettle;
				m_viewInterp = 0.0;
			}
			if (CInputManager::Instance().MouseState(LEFT_MB)) {
				m_gameState = GS_ShotDetect;
				ShowCursor(FALSE);
				SetCursorPos(width, height);
				m_forwardAim.set(0,0,0);
				m_sideAim.set(0,0,0);
			}
			if (CInputManager::Instance().KeyState(VK_SPACE)) {
				m_toggleTolleyMove = !m_toggleTolleyMove;
				CInputManager::Instance().KeyUp(VK_SPACE);
			} 
			if (m_toggleTolleyMove) {
				if (CInputManager::Instance().KeyState(VK_UP))		m_tolleyPos = m_tolleyPos - m_tolleyForward*speed;
				if (CInputManager::Instance().KeyState(VK_DOWN))	m_tolleyPos = m_tolleyPos + m_tolleyForward*speed;
				if (CInputManager::Instance().KeyState(VK_LEFT))	m_tolleyPos = m_tolleyPos + m_tolleyStrafe*speed;
				if (CInputManager::Instance().KeyState(VK_RIGHT))	m_tolleyPos = m_tolleyPos - m_tolleyStrafe*speed;
			} else {
				if (CInputManager::Instance().KeyState(VK_UP))		m_aimPos = m_aimPos - m_tolleyForward*speed*1.5;
				if (CInputManager::Instance().KeyState(VK_DOWN))	m_aimPos = m_aimPos + m_tolleyForward*speed*1.5;
				if (CInputManager::Instance().KeyState(VK_LEFT))	m_aimPos = m_aimPos + m_tolleyStrafe*speed*1.5;
				if (CInputManager::Instance().KeyState(VK_RIGHT))	m_aimPos = m_aimPos - m_tolleyStrafe*speed*1.5;
			}
			m_p1Tolley->setPos(m_tolleyPos.x, m_tolleyPos.y, m_tolleyPos.z);
	
			CCamera::Instance().LookAt(m_tolleyPos.x + m_tolleyForward.x*10 , 5, m_tolleyPos.z + m_tolleyForward.z*10,
										m_aimPos.x, m_aimPos.y, m_aimPos.z,
										0, 1, 0);
		} 
		else if (m_gameState == GS_ShotDetect) 
		{
			if (!CInputManager::Instance().MouseState(LEFT_MB)) {
				ShootMarble(m_forwardAim, m_sideAim, m_aimPos - m_tolleyPos);
				ShowCursor(TRUE);
				m_gameState = GS_DynamicsSettle;
				m_viewInterp = 0.0;
			}
			
			CInputManager::Instance().UpdateMouse(width, height);
			m_sideAim = m_sideAim + m_tolleyForward*CInputManager::Instance().getMouseDX();
			m_forwardAim = m_forwardAim + (m_tolleyStrafe*CInputManager::Instance().getMouseDY());
		}
		
		
		CCamera::Instance().Look();
		m_tolleyPos.set(m_p1Tolley->getPos()[0],
						m_p1Tolley->getPos()[1], 
						m_p1Tolley->getPos()[2]);
		CObjectManager::Instance().UpdateObjects();
		CObjectManager::Instance().DrawObjects();
		//CGLRender::Instance().drawGrid();
		CGLRender::Instance().drawFloor();
		
		CGLRender::Instance().drawAim(m_aimPos.x, m_aimPos.z, m_throbber);
	}

}

void printOut(int x, int y, char * text) {
	glRasterPos2i(x,y);
	int length=strlen(text);
	for (int i = 0; i < length; i++)
	{
		glutBitmapCharacter(GLUT_BITMAP_8_BY_13, text[i]);
	}
}
void CGame::DrawTexts()
{
	for (vector<CMessage*>::iterator it = m_messageList.begin(); it < m_messageList.end(); it++) {
		printOut((*it)->xpos, (*it)->ypos, (*it)->text);
	}
}

void CGame::interpView ()
{
	CVector3 viewPos, viewCtr;
	CVector3 destPos(3, 40, 3);
	CVector3 sourcePos(m_tolleyPos.x + m_tolleyForward.x*10 , 5, m_tolleyPos.z + m_tolleyForward.z*10);
	if (m_viewInterp < 1) {
	m_viewInterp+=m_deltaT;
	viewPos =  sourcePos *(1-m_viewInterp) + destPos * m_viewInterp;
	viewCtr =  m_aimPos *(1-m_viewInterp)  + m_tolleyPos * m_viewInterp;
	} else {
	viewCtr = m_tolleyPos;
	viewPos = destPos;//CCamera::Instance().LookAt( 3, 20, 3, 0, 0, 0, 0, 1, 0 );
	}
	CCamera::Instance().LookAt(viewPos.x, viewPos.y, viewPos.z,
							   viewCtr.x, viewCtr.y, viewCtr.z,
							   0, 1, 0);
}

void 
CGame::CheckCollisions(dBodyID b1, dBodyID b2)
{
	CGameObject* obj1 = CObjectManager::Instance().getObject(b1);
	CGameObject* obj2 = CObjectManager::Instance().getObject(b2);

	if (((CMarble*)obj1)->getVel() > 0.3 || ((CMarble*)obj2)->getVel() > 0.3)	{		
		float volume = max(((CMarble*)obj1)->getVel(), ((CMarble*)obj2)->getVel());
		m_soundManager.playFX(volume * 2.0f);
	}
}
void
CGame::ShootMarble(CVector3 forward, CVector3 side, CVector3 aim)
{
	double yVel = aim.Magnitude()/30.0;
	if (yVel > 5.0) yVel = 10.0;
	m_p1Tolley->setVel(aim.x*1.3,yVel, aim.z*1.3);
	if (forward.Magnitude() != 0)
		m_p1Tolley->AddTorque(forward.x/10, forward.y/10, forward.z/10);
	if (side.Magnitude() != 0)
		m_p1Tolley->AddTorque(side.x/3, side.y/3, side.z/3);
	m_gameState = GS_DynamicsSettle;
}

void
CGame::OnKeyUp(WPARAM w)
{

}

void
CGame::OnKeyDown(WPARAM w)
{

	
}
