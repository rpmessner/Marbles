#include "CTimer.h"

#include <windows.h>

CTimer::CTimer()
{	
	m_lastTime = 0;
	m_totalTime = 0;
	LARGE_INTEGER temp;
	QueryPerformanceFrequency(&temp);
	m_frequency = temp.QuadPart;
}

CTimer::~CTimer()
{
	;
}

void CTimer::FrameUpdate()
{
	LARGE_INTEGER temp;
	QueryPerformanceCounter(&temp);
	m_lastTime = m_totalTime;
	m_totalTime = temp.QuadPart;
}

double CTimer::getDeltaT() const
{
	return (double)(m_totalTime-m_lastTime)/(double)m_frequency;
}

double CTimer::getTime() const
{
	return (double)m_totalTime/(double)m_frequency;
}
