#ifndef SOUND_MANAGER_H
#define SOUND_MANAGER_H

#include "singleton.h"
#include "fmod.h"

#define NUM_MUSIC_TRACKS 2

class SoundManager: public Singleton<SoundManager>
{
public:
	SoundManager();
	~SoundManager();

	void	init();

	void	playFX(float vol);

	void	startMusic();
	void	stopMusic();
	void	nextMusicTrack();

	void	skipToNextTrack();
	void	toggleMusic();

private:

	bool			m_musicPlaying;
	int				m_musicPlayingIndex;
	
	FSOUND_STREAM*	m_currentMusicTrack;
	FSOUND_SAMPLE*  m_collideFXSamples[3];

	static const char*	collisionSoundFX[3];
	static const char*	musicFileNames[NUM_MUSIC_TRACKS];

};

#endif