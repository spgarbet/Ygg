// ygg_manager.scd
// Manager class for Ygg drone synthesizer
// Requires: ygg_synths.scd to be loaded first

(
// Load SynthDefs if not already loaded
if(SynthDescLib.global[\yggVoice].isNil)
{
  "Loading Ygg SynthDefs...".postln;
  thisProcess.nowExecutingPath.dirname +/+ "ygg_synths.scd".load;
  s.sync;
};

// ====================================================================
// YGG ENGINE MANAGER CLASS
// ====================================================================
~ygg = (
  // Audio buses
  voiceBuses: nil,
  modBuses: nil,
  lfoBus: nil,
  delayBus: nil,
  driveBus: nil,
  
  // Synth nodes
  voices: nil,
  crossMod: nil,
  lfo: nil,
  delay: nil,
  drive: nil,
  
  // Voice allocation
  voiceIdx: 1,  // ring buffer index for voice stealing
  activeNotes: nil,  // dict of midi note -> voice index
  
  // Global parameters
  hold: 0.0,
  vibratoDepth: 0.01,
  routing: 0,  // 0=neighbor, 1=cross, 2=loop
  
  // ================================================================
  // INITIALIZATION
  // ================================================================
  init: {
    arg self;
    
    s.waitForBoot
    {
      // Allocate buses
      self.voiceBuses = 8.collect { Bus.audio(s, 2) };
      self.modBuses = 8.collect { Bus.audio(s, 1) };
      self.lfoBus = Bus.audio(s, 1);
      self.delayBus = Bus.audio(s, 2);
      self.driveBus = Bus.audio(s, 2);
      
      // Initialize voice tracking
      self.voices = Array.newClear(8);
      self.activeNotes = Dictionary.new;
      
      // Wait for SynthDefs to load
      s.sync;
      
      // Create synth chain in reverse order
      self.drive = Synth(\yggDrive, [
        \in, self.delayBus,
        \out, 0,
        \distDrive, 1.0,
        \distMix, 0.0
      ], addAction: \addToTail);
      
      self.delay = Synth(\yggDelay, [
        \in, self.delayBus,
        \out, self.driveBus,
        \delayTime1, 0.25,
        \delayTime2, 0.5,
        \delayFB, 0.3,
        \delayMix, 0.3,
        \lfoBus, self.lfoBus,
        \modType, 0
      ], addAction: \addToHead);
      
      self.lfo = Synth(\yggLFO, [
        \out, self.lfoBus,
        \freqA, 0.1,
        \freqB, 0.2,
        \style, 0
      ], addAction: \addToHead);
      
      self.crossMod = Synth(\yggCrossMod, [
        \voice1Bus, self.voiceBuses[0],
        \voice2Bus, self.voiceBuses[1],
        \voice3Bus, self.voiceBuses[2],
        \voice4Bus, self.voiceBuses[3],
        \voice5Bus, self.voiceBuses[4],
        \voice6Bus, self.voiceBuses[5],
        \voice7Bus, self.voiceBuses[6],
        \voice8Bus, self.voiceBuses[7],
        \out1, self.modBuses[0],
        \out2, self.modBuses[1],
        \out3, self.modBuses[2],
        \out4, self.modBuses[3],
        \out5, self.modBuses[4],
        \out6, self.modBuses[5],
        \out7, self.modBuses[6],
        \out8, self.modBuses[7],
        \routing, self.routing
      ], addAction: \addToHead);
      
      "Ygg Engine initialized.".postln;
    };
  },
  
  // ================================================================
  // NOTE ON - with voice stealing
  // ================================================================
  noteOn: {
    arg self, note, vel=127;
    var voiceNum, freq, amp;
    
    freq = note.midicps;
    amp = vel.linlin(0, 127, 0, 1);
    
    // Check if note already playing
    if(self.activeNotes[note].notNil)
    {
      voiceNum = self.activeNotes[note];
      // Re-trigger existing voice
      self.voices[voiceNum].set(\gate, 0);
      self.voices[voiceNum].free;
    }
    {
      // Steal oldest voice (ring buffer)
      voiceNum = self.voiceIdx - 1;  // convert to 0-indexed
      self.voiceIdx = (self.voiceIdx % 8) + 1;
      
      // Free old voice if exists
      if(self.voices[voiceNum].notNil)
      {
        self.voices[voiceNum].set(\gate, 0);
        self.voices[voiceNum].free;
      };
    };
    
    // Create new voice
    self.voices[voiceNum] = Synth(\yggVoice, [
      \out, self.voiceBuses[voiceNum],
      \voiceNum, voiceNum,
      \freq, freq,
      \amp, amp,
      \gate, 1,
      \attack, 0.1,
      \release, 1.0,
      \hold, self.hold,
      \vibratoFreq, 5.0,
      \vibratoDepth, self.vibratoDepth,
      \harmonics, 0.0,
      \pitchBend, 0.0,
      \pressure, 1.0,
      \modDepth, 0.0,
      \modBus, self.modBuses[voiceNum],
      \lfoBus, self.lfoBus
    ], addAction: \addToHead);
    
    self.activeNotes[note] = voiceNum;
    
    ("Note On: " ++ note ++ " -> Voice " ++ voiceNum).postln;
  },
  
  // ================================================================
  // NOTE OFF
  // ================================================================
  noteOff: {
    arg self, note;
    var voiceNum;
    
    voiceNum = self.activeNotes[note];
    
    if(voiceNum.notNil)
    {
      if(self.voices[voiceNum].notNil)
      {
        self.voices[voiceNum].set(\gate, 0);
        ("Note Off: " ++ note ++ " (Voice " ++ voiceNum ++ ")").postln;
      };
      
      self.activeNotes.removeAt(note);
    };
  },
  
  // ================================================================
  // MPE CONTROLS
  // ================================================================
  setPitchBend: {
    arg self, note, bendSemitones;
    var voiceNum = self.activeNotes[note];
    
    if(voiceNum.notNil)
    {
      self.voices[voiceNum].set(\pitchBend, bendSemitones);
    };
  },
  
  setPressure: {
    arg self, note, pressure;  // 0-1
    var voiceNum = self.activeNotes[note];
    
    if(voiceNum.notNil)
    {
      self.voices[voiceNum].set(\pressure, pressure);
    };
  },
  
  // ================================================================
  // VOICE PARAMETER CONTROLS
  // ================================================================
  setVoiceParam: {
    arg self, voiceNum, param, value;
    
    if(self.voices[voiceNum].notNil)
    {
      self.voices[voiceNum].set(param, value);
    };
  },
  
  setAllVoices: {
    arg self, param, value;
    
    8.do
    {
      arg i;
      if(self.voices[i].notNil)
      {
        self.voices[i].set(param, value);
      };
    };
  },
  
  // ================================================================
  // GLOBAL PARAMETER CONTROLS
  // ================================================================
  setHold: {
    arg self, value;  // 0-1
    self.hold = value.clip(0, 1);
    self.setAllVoices(\hold, self.hold);
  },
  
  setVibratoDepth: {
    arg self, value;
    self.vibratoDepth = value;
    self.setAllVoices(\vibratoDepth, self.vibratoDepth);
  },
  
  setRouting: {
    arg self, value;  // 0=neighbor, 1=cross, 2=loop
    self.routing = value.clip(0, 2);
    self.crossMod.set(\routing, self.routing);
  },
  
  setLFO: {
    arg self, freqA, freqB, style;
    self.lfo.set(\freqA, freqA, \freqB, freqB, \style, style);
  },
  
  setDelay: {
    arg self, time1, time2, mod1, mod2, fb, mix, modType;
    self.delay.set(
      \delayTime1, time1,
      \delayTime2, time2,
      \delayMod1, mod1,
      \delayMod2, mod2,
      \delayFB, fb,
      \delayMix, mix,
      \modType, modType
    );
  },
  
  setDrive: {
    arg self, drive, mix;
    self.drive.set(\distDrive, drive, \distMix, mix);
  },
  
  // ================================================================
  // CLEANUP
  // ================================================================
  free: {
    arg self;
    
    self.voices.do { arg v; if(v.notNil) { v.free } };
    self.crossMod.free;
    self.lfo.free;
    self.delay.free;
    self.drive.free;
    
    self.voiceBuses.do { arg b; b.free };
    self.modBuses.do { arg b; b.free };
    self.lfoBus.free;
    self.delayBus.free;
    self.driveBus.free;
    
    "Ygg Engine freed.".postln;
  }
);

"Ygg Manager loaded.".postln;
)
