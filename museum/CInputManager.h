#ifndef CINPUT_MANAGER_H
#define CINPUT_MANAGER_H

#include "singleton.h"

#include <windows.h>

class CInputManager : public Singleton<CInputManager>
{
public:
	CInputManager();
	~CInputManager();
	bool KeyState(WPARAM w)	{ return m_keys[w]; }
	void KeyDown(WPARAM w) { m_keys[w] = true; }
	void KeyUp  (WPARAM w) { m_keys[w] = false; }
	bool MouseState (int i) { 
		if (i>2)return false; else return m_mb[i]; 
	}
	bool CheckInput ();
	int getMouseDX () { return m_dx; }
	int getMouseDY () { return m_dy; }
	
	void UpdateMouse(int middleX, int middleY);
private:
	bool m_keys[256];
	bool m_mb[3];
	int  m_lastX;
	int	 m_lastY;
	int  m_dx; 
	int  m_dy;
};

#endif //CINPUT_MANAGER_H