#ifndef CGAME_H
#define CGAME_H

#include "Singleton.h"
#include "CGLRender.h"
#include "CCamera.h"
#include "CTimer.h"
#include "ODEManager.h"
#include "CObjectManager.h"
#include "CMarble.h"
#include "ObjectFactory.h"
#include "CInputManager.h"
#include "SoundManager.h"

#include <windows.h>
#include <queue>
#include <vector>

using std::queue;

typedef enum {
	GS_Menu,
	GS_AimShot,
	GS_LoadLevel,
	GS_ShotDetect,
	GS_DynamicsSettle,
	GS_NumGameStates
} GameState;

class CMessage
{
public:
	//CMessage();
	//~CMessage();
	int xpos;
	int ypos;
	char* text;
};

class CGame : public Singleton<CGame>
{
public:
	CGame();
	~CGame();
	
	// Utility Functions_
	WPARAM Start();
	void OnKeyUp(WPARAM w);
	void OnKeyDown(WPARAM w);
	// Game Functions
	bool CreateMarbles (int number);
	void CheckCollisions(dBodyID, dBodyID);
	void Finish () { m_quit = true; }

private:
	void interpView ();
	void MainLoop();
	void ShootMarble(CVector3 forward, CVector3 side, CVector3 aim);
	std::vector<CMarble*> m_marbleList;
	
	// a Tolley is the larger marble with which
	// the player shoots. 
	CTolley*		m_p1Tolley;
	CTolley*		m_p2Tolley;
	// Vectors for keeping track of the
	// shot aim
	CVector3		m_tolleyForward;
	CVector3		m_tolleyStrafe;
	CVector3		m_forwardAim;
	CVector3		m_sideAim;
	// Aim Shot Mode Variables
	CVector3		m_tolleyPos;
	CVector3		m_aimPos;
	
	// here are my main modules
	CTimer			m_timer;
	CGLRender		m_renderer;
	CCamera			m_camera;
	CObjectManager	m_objectManager;
	ODEManager		m_odeManager;
	CInputManager	m_inputManager;
	GameState		m_gameState;
	SoundManager	m_soundManager;

	int				m_p1Score;
	int				m_p2Score;

	double			m_throbber; // just a float that will go between 1-0 and back w/ time
	double			m_throbIncrSign;
	double			m_viewInterp;
	double			m_deltaT;
	char			m_windowTitle[20];
	vector<CMessage*>	m_messageList;
	void			DrawTexts();

	bool			m_toggleTolleyMove;
	bool			m_keys[256];
	bool			m_pause;
	bool			m_quit;
};

#endif
