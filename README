# Hexpress

[Hexpress on Google Play](https://play.google.com/store/apps/details?id=com.castlewrath.hexpress)

Hexpress is a digital musical instrument for mobile devices. The app is developed in Lua language and uses LÖVE library for visuals, input and audio. Instead of emulating some traditional instruments, the project starts from clean slate and tries to design a digital instrument that plays to strengths of platform.

It is available as free-of-charge Android app (without ads) and as an open-source project.

![App screenshot](media/screenshot_trail.png?raw=true)


# Hex layout

Most music apps use piano or guitar layout. Both are lousy choices for touchscreen, since the device screen is much smaller than those instruments. Scrolling through octaves or fingerboard is not really a solution.

Good note layout should be chromatic, all notes/keys should be equal (unlike piano that favors C major), and it should make good use of 2D screen surface. It should also support using instrument with just single thumb while the phone is held, or with all ten fingers with device on the desk.

After some research, [Harmonic table note layout](https://en.m.wikipedia.org/wiki/Harmonic_table_note_layout) was chosen as best fit. It satisfies most of above requirements while also having simple patterns for chords/arpeggios. It was used historically on some instruments and also as a method for music theory analysis, so it seems like a right choice.

# Sound stack

LÖVE uses openal-soft library for cross-platform audio. It supports spatial audio, real-time effects (reverb, chorus, distortion, echo, flanger, modulator, compressor, equalizer), and sound capture. It lacks some effects (wah, long delay, octaver...), ability to loop only part of the sample and support for modular synthesis (oscillators, filters, envelopes).

Currently the app uses samples from NSynth Dataset, made available by Google Inc. under a Creative Commons Attribution 4.0 International (CC BY 4.0) license. They are versatile and good enough for demonstration, but not really ideal. Some samples end abruptly, and they are only 3 seconds long so notes cannot be sustained indefinitely. A better solution is needed.

One large setback for serious digital instrument is the audio latency, the lag between touch and resulting sound. It is affected by touch sensing latency, audio software stack (openal-soft), the Android OS and hardware audio drivers. Some of latency can be eliminated by correctly configuring the audio stack (still in progress). Android was not designed for professional audio applications, but there were some improvements in recent years. Hopefully with some more effort I can get the latency bellow 20 ms, at least for some device.

# Why?

Traditional instruments sound rich and are very expressive. Any small variation in playing can affect tone loudness, timbre and pitch. Most traditional instruments can also be just picked up and played without any setup beyond tuning. On the other hand, digital synthesizers have huge diversity in sounds, but they are not as expressive and can take a long while to configure. They expose large number of parameters to user, usually in form of hierarchical settings. Parameters can also be mapped to knobs/wheels with different value ranges and mapping functions. This can be overwhelming and frustrating for user, while still not reaching desired flexibility.

Hexpress attempts to merge expressiveness and simplicity of traditional instrument with possibilities of digital instrument. You can just launch the app and start playing. Because it's always with you on your phone and can be played in any situation (with headphones), it has huge advantage over traditional instruments. There's no UI to detract you from playing, which also makes the app kid-friendly. Tone can be affected in real-time through the use phone sensors, which feels responsive.

Maybe we can do better than clunky menues with sliders and checkboxes? Lua is a beautiful interpreted language, so why not expose good API instead? Advanced user could shape and control the sound beyond anything digital synthesizers could do, with just few lines of code.

Hexpress has potential to become hackable even beyond sound design. One could experiment with different note layouts, chord triggering, arpeggiators, advanced auto-accompaniment, or even hook up some experimental tone generation methods (neural-network synth, for example).

# TODOs

* refactor the code to decouple note triggering from synthesis
* investigate integrating Faust DSP effects into openal-soft filter/effect system
* work on lowering the audio latency
* implement note velocity based on finger touching surface measurement
