#include "CInputManager.h"
#include "CGame.h"

#include <windows.h>

CInputManager::CInputManager()
{
	for (int i = 0; i < 256; i++)
		m_keys[i] = false;
	for (int i = 0; i < 3; i++)
		m_mb[i] = false;
}

CInputManager::~CInputManager()
{
	;
}

bool
CInputManager::CheckInput ()
{
	MSG msg;
	if (PeekMessage(&msg,NULL,0,0,PM_REMOVE))		{
		if (msg.message==WM_QUIT) {					// Have We Received A Quit Message?
			CGame::Instance().Finish();								// If So done=TRUE
		} else if (msg.message == WM_KEYDOWN)		{		// Is A Key Being Held Down?
			m_keys[msg.wParam] = true;
		} else if (msg.message == WM_KEYUP)			{
			m_keys[msg.wParam] = false;
		} else if (msg.message == WM_LBUTTONDOWN)	{
			m_mb[0] = true;
		} else if (msg.message == WM_LBUTTONUP)		{
			m_mb[0] = false;
		} else if (msg.message == WM_RBUTTONDOWN)	{
			m_mb[2] = true;
		} else if (msg.message == WM_RBUTTONUP)		{
			m_mb[2] = false;
		} else {
			TranslateMessage(&msg);				// Translate The Message
			DispatchMessage(&msg);				// Dispatch The Message
		}
		return true;
	} else {
		return false;
	}
}
void CInputManager::UpdateMouse(int middleX, int middleY)
{
	POINT mousePos;									// This is a window structure that holds an X and Y
	GetCursorPos(&mousePos);						

	SetCursorPos(middleX, middleY);							

	// Get the direction the mouse moved in, but bring the number down to a reasonable amount
	m_dx = middleX - mousePos.x;		
	m_dy = middleY - mousePos.y;		


}	