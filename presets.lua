local no_envelope = { A = 0.04, D = 0.05, S = 0.99, R = 0.30}

local presets = {

{ -- organ
  envelope = {
    A = 0.40,
    D = 0.20,
    S = 0.85,
    R = 0.35,
  },
  samples = {
    C = 'samples/brite48000.wav',
  },
},

{ --rhodes
  envelope = no_envelope,
  samples = {
    C = 'samples/rhodes_G3_3.wav',   -- TODO: tune to G!
  },
},

}
return presets
