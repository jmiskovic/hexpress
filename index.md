# Hexpress

[Hexpress on Google Play](https://play.google.com/store/apps/details?id=com.castlewrath.hexpress)

Hexpress is a playground for constructing interactive musical experiments for use on Android devices. It's built on top of LÖVE framework. It is available as free-of-charge Android app and open-source project.

![App screenshot](media/screenshot_trail.png?raw=true)

# Note layout

Hexpress currently implements two note layouts, hexagonal note layout and fretboard.

Hexagonal layout (in hexpad module) is based on [Harmonic table note layout](https://en.wikipedia.org/wiki/Harmonic_table_note_layout). This arrangement has quite simple patterns for chords & arpeggios, and it was used historically as a method for music theory analysis.

Fretboard is mostly modeled after guitar, but can also be used for other instruments. It supports sliding and different tuning.

# Design & architecture

Hexpress runs on Android & desktop versions of LÖVE framework. LÖVE is an *awesome* framework for 2D games, which also makes it suitable virtual instruments. Hexpress uses still unreleased LÖVE v0.11 that can be found on *minor* branch of LÖVE repo.

LÖVE uses openal-soft library for cross-platform audio. It supports spatial audio, real-time effects (reverb, chorus, distortion, echo, flanger, modulator, compressor, equalizer), and sound capture. It's not meant for professional music applications, but so far it's proven to be effective for the needed scope.

Platform supports unlimited number of instruments. Several instruments are provided in *patches* subdirectory. When application starts, a *selector* module scans for patches and presents them to user for selection. For this purpose, patch contains icon() function that is called each frame by selector to render representation of patch to user. Once a patch is selected, it starts executing in place of selector module.

Each frame, the input controls are read, processed and forwarded to patch. The patch can use a note layout module (hexpad, fretboard) to convert input touches to notes. Then this information can be manipulated to implement note bending, vibrato, chords/arpeggios or anything else. This manipulated information is sent to *sampler* module to convert to audio output. Sampler selects correct audio sample, manipulates its pitch to adapt it to desired note and tweaks its volume according to [ADSR envelope](https://en.wikipedia.org/wiki/Synthesizer#ADSR_envelope). Sampler is heavily customizable and controllable from Lua script.

[Seed patch]('patches/seed/seed.lua') is well-documented example of a patch.

Aside from built-in patches, Hexpress Android app can open external project with different set of patches or changed codebase. Lua is interpreted language, so these changes don't require recompilation or app reinstallation. To see run new version on your phone, copy content of whole project to internal phone memory and use file browser to open 'main.lua' with Hexpress app.

# Audio latency

One large set-back for serious digital instrument is the audio latency, the lag between touch and resulting sound. It is affected by touch sensing latency, audio software stack (openal-soft), the Android OS and hardware audio drivers. Some of latency can be eliminated by correctly configuring the audio stack, this is still in progress. Android was not designed for professional audio applications, but there were some improvements in recent years. Hopefully with some more effort latency can be lowered bellow 20 ms, at least for some devices.
