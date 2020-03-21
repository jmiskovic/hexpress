# Hexpress

[Hexpress app](https://play.google.com/store/apps/details?id=com.castlewrath.hexpress) on Google Play

Hexpress is a playground for constructing interactive musical experiments for use on Android devices. It's built on top of LÖVE framework. It is available as free-of-charge Android app and open-source project.

![App screenshot](media/garage_framed.jpg)


# Note layouts

Hexpress currently implements three note layouts:

* hexagonal note layout
* fretboard arrangement
* free-form layout

Hexagonal layout is based on [Harmonic table note layout](https://en.wikipedia.org/wiki/Harmonic_table_note_layout). This arrangement has quite simple patterns for chords & arpeggios, and it was used historically as a method for music theory analysis and composition.

Fretboard is mostly modeled after guitar, but can also be used for other instruments. It supports any number of strings with customizable tuning. Compared to hexagonal layout, fretboard can be considered as generalized rectangle tiling, as strings and frets correspond to two axes of symmetry.

Free-form layout allows placing any number of circular zones that act as note triggers. It's meant to be used for percussive instruments or for instruments with irregular note arrangements.


# Design & architecture

Hexpress runs on Android & desktop versions of LÖVE framework. LÖVE is an *awesome* framework for 2D games, which also makes it decent fit for implementing musical instruments.

LÖVE uses openal-soft library for cross-platform audio. It supports spatial audio, real-time effects (reverb, chorus, distortion, echo, flanger, modulator, compressor, equalizer), and sound capture. It's not meant for professional music applications, but so far it's proven to be effective for the needed scope. The released Hexpress app makes some modifications to LÖVE framework code. The framework code and Android building environment is currently not included in this repository because of maintainability problems. Please open an issue if this is of any interest.

Hexpress supports any number of virtual instruments. Several instruments are provided in *patches* subdirectory. When application starts, a `selector.lua` module scans for patches and presents them to user for selection. For this purpose, patch contains `icon()` function that is called each frame by selector to render representation of patch to user. Once a patch is selected, it starts executing in place of selector module. The phone's *back* button unloads current patch and returns execution to selector.

The patch script acts like a mini-app and has full control over input, sound and rendering. Some patches use this to implement specialized visualizations and control methods. Patch creates a runnable instance during `load()` method, and this instance is later given control with `process(dt)` and `draw()` calls.

Each frame, an empty *stream* table is created in `main.lua`. Touch inputs and phone tilt are read and processed in `control.lua` and forwarded to patch within the *stream* table. The patch can use any note layout (`hexpad.lua`, `fretboard.lua`, `freeform.lua`) to convert touch locations into note pitch. During this conversion, it is determined if touch triggers new note (`noteRetrigger` property), or if it is holding down same note as on previous frame. All this information is stored back into the *stream*. It can be further manipulated by patch to implement note bending, vibrato, chords/arpeggios or other real-time musical techniques.

The *stream* is then sent to *sampler* module to convert to audio output. Each sampler keeps table of audio samples with assigned note pitch and velocity (volume). For each new note, the sampler will select correct audio sample based on best match for note's pitch and velocity. It will then tune the pitch of sample to played note and start sample playback. The volume of playback is constantly adjusted according to [ADSR envelope](https://en.wikipedia.org/wiki/Synthesizer#ADSR_envelope). The maximum number of simultaneous sample playbacks is customizable, if limit is reached the oldest sample is stopped to make room for new note. Sampler is heavily customizable during initialization from patch, and some real-time parameters are controllable during execution.

The drawing of visuals is mostly done inside note layout modules (`hexpad.lua`, `fretboard.lua`, `freeform.lua`). They render iterate through grid of note layout to show positions of notes, with currently played notes being rendered with different color/size/animation. There are three level of granularity for customizing instrument visualizations. Easiest modification is just changing color scheme of note layout (for example `choir.lua`). More customization is possible by re-using grid layout but overriding drawing of individual cells (for example `analog.lua`). For complete control, note layout rendering is not used at all and rendering is re-implement inside the patch (this makes `strings.lua` look unique).

Aside from using built-in patches, Hexpress app can also open external project with different set of patches, or a completely changed codebase. Lua is interpreted language, so these changes don't require recompilation or app re-installation. The Hexpress app is almost identical to official LÖVE for Android app, with differences being app icon and name, expected location of interpreted code on internal storage, and tweaks for lower audio latency.


# Creating and modifying instruments

Creating new instrument is done by of collecting audio samples, processing them, and creating a lua script to implement behavior.

For decent quality, there should be at least three samples per one octave. Instrument samples need to be in mono. Some samples require fine-tuning to get them into correct pitch. It is also good idea to cut off any silence at beginning of sample, at the zero crossing to prevent popping. Audacity is good audio editor for processing, while Sox can be used for automatic normalization and data compression.

The lua script for patch has to be named same as patch directory. The script is quite straightforward to create by modifying an existing patch (`choir.lua` patch can serve as a good template). The `load()` function is executed once to create a sampler and feed it a list of samples and parameters of ADSR envelope. Functions `process()` and `draw()` can be left unchanged for simple instruments.

As mentioned, modified codebase doesn't require any code compilation or building of APK. The installed Hexpress app can load modified codebase instead of built-in codebase. This allows for tweaking of any settings, designing of new insturments, modifying visuals, changing sound samples, all by modifying files on your phone.

To run modified version on your phone, copy content of whole repository to internal device memory under directory `/sdcard/hexpress` and launch the app. The app will scan for project files in this directory and run those instead of default project bundled within the app. It's good idea to change the background color in selector.lua, to verify which version is currently running on device: `background = {l.rgba(0x003f20ff)}`

Please note: this automatic code-loading feature will prevent you from seeing the updates in official app. To switch back to official project, just delete or rename `hexpress` directory in device memory, or pull new version and update on phone.


# Unexplored ideas

Here are some promising ideas that I never got around to implementing.

A monophonic instrument that works in portrait mode, playable with single thumb. Sometimes you want to keep phone in the pocket and still make noise.

Capture sound with microphone, do on-the-fly harmonic analysis, and display the results as overlay on the hexagonal grid. This would enable strong feedback between outside performed music and the virtual instrument itself. One could whistle a melody and then play it flawlessly just by pressing the highlighted notes.

Allow for zooming and scrolling of the underlaying musical grid and thereby extending the musical range of instrument. Being able to bring any note to screen center would also make it more useful for studying music theory.

Explore the musical theory concepts by implementing different note arrangements - Wicki-Hayden layout, circle-of-fifths, Janko piano layout and others.

Add an intelligent music assistant that automatically adds harmonic accompaniment to played melody, and suggests next melody note based on previous notes and learned model.

Implement the layered looper that would enable whole compositions inside the app. The looper would record note events and repeat them periodically. This looper could be combined with intelligent assistant - you would teach it to play something by repeating a pattern until it's well learned. The repetition in learning process would also serve to eliminate glitches/mistakes.
