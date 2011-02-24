#include "SoundManager.h"
#include <stdlib.h>

const char* SoundManager::musicFileNames[NUM_MUSIC_TRACKS] = { "music/marbles_music1.mp3", "music/marbles_music2.mp3"};

const char* SoundManager::collisionSoundFX[3] = { "music/ballHit1.wav", "music/ballHit2.wav", "music/ballHit3.wav" };

SoundManager::SoundManager()
{
	m_musicPlaying = false;
}

SoundManager::~SoundManager()
{

}

//------------------------------------------------------------
//	Callback to go to the next stream
//------------------------------------------------------------

signed char F_CALLBACKAPI endcallback(FSOUND_STREAM *stream, void *buff, int len, void *param)
{
	SoundManager::Instance().stopMusic();
	SoundManager::Instance().nextMusicTrack();
	SoundManager::Instance().startMusic();	

	return false;
}

void SoundManager::init()
{
	//init sound system
	FSOUND_Init(44100, 32, 0);
	m_musicPlayingIndex = 0;

	for(int i=0; i < 3; i++)
	{
		m_collideFXSamples[i] = FSOUND_Sample_Load(FSOUND_FREE, 		
								collisionSoundFX[i],
								FSOUND_NORMAL | FSOUND_LOOP_OFF, 0 ,0);
	}
}

void SoundManager::playFX( float vol)
{
	int c =0;


		int r = rand() % 3;
		c = FSOUND_PlaySound(FSOUND_FREE, m_collideFXSamples[r]);


	if(vol != 1.0f)
	{
		 FSOUND_SetVolume(c, 255 * (int)vol);
	}

}

void SoundManager::startMusic()
{
	m_currentMusicTrack = FSOUND_Stream_Open(musicFileNames[m_musicPlayingIndex],
								FSOUND_NORMAL | FSOUND_LOOP_OFF, 0 ,0);

	FSOUND_Stream_SetEndCallback(m_currentMusicTrack, endcallback, 0);

	FSOUND_Stream_Play(FSOUND_FREE, m_currentMusicTrack);

	m_musicPlaying = true;

}

void SoundManager::stopMusic()
{
	if(m_currentMusicTrack)
		FSOUND_Stream_Close(m_currentMusicTrack);

	m_currentMusicTrack = 0;	
	m_musicPlaying = false;
}

void SoundManager::nextMusicTrack()
{
	m_musicPlayingIndex++;
	if(m_musicPlayingIndex >= NUM_MUSIC_TRACKS)
		m_musicPlayingIndex=0;

}

void SoundManager::skipToNextTrack()
{
	stopMusic();
	nextMusicTrack();
	startMusic();

}

void SoundManager::toggleMusic()
{
	if(m_musicPlaying)
		stopMusic();
	else
		startMusic();
}