//------------------------------------------------------------------
//	CTimer
//------------------------------------------------------------------


#ifndef CTIMER_H
#define CTIMER_H

#include "Singleton.h"

class CTimer: public Singleton<CTimer>
{
public:

	CTimer();
	~CTimer();
	
	double getDeltaT() const;
	double getTime() const;
	
	void FrameUpdate ();

private:	
	__int64 m_frequency;
	__int64	m_lastTime;
	__int64	m_totalTime;
};

#endif
