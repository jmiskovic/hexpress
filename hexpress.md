Hexpress is a musical toy you can carry in your pocket. 

It uses honeycomb keyboard arrangement which has several nice properties:
  * good utilization of mobile screen
  * easy to transpose - just play same patterns starting from different key
  * most chord shapes can be executed with single finger swipe
  * typical scale notes and melody runs are alternated between two hands; they can be played with speed and precision
  * large intervals are as accessible as smaller intervals
  * only two positions for each scale/arpeggio (starting note on left and on right hand)

Aside from honeycomb keyboard, the app has buttons called SOUND, EFFECT, PRESET.

SOUND button changes current instrument sound in random fashion. Just tap the button to get random new sound. You can also record short sample and use it as an instrument. Just produce the sample you want and hold Insturment button until it turns red. Release the button to stop recording and your recorded sample is now used as insturment sound.

EFFECT button applies random effect with random parameters to your sound. Just keep pressing until you get the effect you like. Long press to enable/disable ambient echo.

PRESET button can store and recall the instrument/effect configuration. Hold the button for a second to save configuration, and press shortly to recall it later. Stored configuration is available across sessions.

Hexpress isn't suited for serious musicians. Many features are limited and it sounds dinky by design. More ambitious musical instrument is currently under development.

Custom button locations
A  -4, 1  SND 
D  -4, 2  FX
G  -4, 3  PAD
C#  4,-3  P1
F#  4,-2  P2
B   4,-1  P3

Speakers
-4, 0
-4, 4
 4,-4
 4, 0

DOINs:
    * special handling of 4 side tiles to custom buttons, tap/hold

TODOs:
    * 4 corner tiles to speaker mesh (visual gimick, key still produces tone)
    * tile note names impressed (choose font), C major tiles lighter than other tiles
    * tiles visually pressed (depth as per ADSR)
    * random effect key, reverb enable/disable
    * move C to lower-left G# position
    * tweak ADSR to allow for chords and melodies
    * make a decent sound or 5
    * record sample
    * save/recall instrument & effect
    * persist across sessions
    * stereo utilization
    * back button exits app
    * touchmove to pitch-shift -> vibrato?
    * tilt to volume?
    * remove configuration
    * handle different screen resolutions
    * checking for EFX/latency/recording capabilities
    * package love scripts for deployment
    * sign apk and deliver to store

BUGs:
    * when switching from and back to app, sound is muted
    * ADSR is buggy, stops playing if note is held for > ~10s


Latency: 
  Android around 150ms

