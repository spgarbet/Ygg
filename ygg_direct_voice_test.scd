// ====================================================================
// YGG VOICE DIRECT TEST (bypassing manager)
// Tests the yggVoice SynthDef directly using pressure control
// Based on CleanroomDemo.sc pattern
// ====================================================================

// IMPORTANT: Load ygg_synths.scd first!
// Then run these tests

// ====================================================================
// TEST 1: Basic Pressure Control
// ====================================================================
(
"=== TEST 1: Basic Pressure Control ===".postln;
s.waitForBoot({
  // Create voice directly
  ~voice = Synth(\yggVoice, [
    \out, 0,
    \freq, 440,
    \amp, 0.5,
    \pressure, 0,
    \hold, 0.3,
    \attack, 2,
    \release, 3,
    \harmonics, 0.0
  ]);
  
  // Define control functions
  ~setPressure = { |value|
    ~voice.set(\pressure, value);
    "SetPressure: %".format(value).postln;
  };
  
  ~setHold = { |value|
    ~voice.set(\hold, value);
    "SetHold: %".format(value).postln;
  };
  
  "Voice created. Try:".postln;
  "~setPressure.value(1.0);  // Full volume".postln;
  "~setPressure.value(0.0);  // Release".postln;
  "~setHold.value(0.0);      // Change hold".postln;
});
)

// Try these manually:
~setPressure.value(1.0);   // Attack to full
~setPressure.value(0.5);   // Drop to half
~setPressure.value(0.0);   // Release
~setHold.value(0.0);       // Allow full release
~voice.free;

// ====================================================================
// TEST 2: Automated Release Test (Most Important!)
// ====================================================================
(
"=== TEST 2: Automated Release Test ===".postln;
s.waitForBoot({
  ~voice = Synth(\yggVoice, [
    \out, 0,
    \freq, 440,
    \amp, 0.5,
    \pressure, 0,
    \hold, 0.0,  // No hold - should release fully
    \attack, 1,
    \release, 3,
    \harmonics, 0.0
  ]);
  
  ~setPressure = { |value|
    ~voice.set(\pressure, value);
    "SetPressure: %".format(value).postln;
  };
  
  fork {
    "Starting...".postln;
    1.wait;
    
    "Setting pressure to 1.0 (attack over 1 second)".postln;
    ~setPressure.value(1.0);
    
    2.wait;
    "Voice should be at full volume now".postln;
    
    2.wait;
    "Setting pressure to 0.0 (release over 3 seconds)".postln;
    ~setPressure.value(0.0);
    
    1.wait;
    "Releasing...".postln;
    
    3.wait;
    "Should be silent now!".postln;
    
    1.wait;
    ~voice.free;
    "Test complete".postln;
  };
});
)

// ====================================================================
// TEST 3: Hold Threshold Behavior
// ====================================================================
(
"=== TEST 3: Hold Threshold Test ===".postln;
s.waitForBoot({
  ~voice = Synth(\yggVoice, [
    \out, 0,
    \freq, 330,
    \amp, 0.5,
    \pressure, 0,
    \hold, 0.4,
    \attack, 3,
    \release, 3,
    \harmonics, 0.0
  ]);
  
  ~setPressure = { |value|
    ~voice.set(\pressure, value);
  };
  
  ~setHold = { |value|
    ~voice.set(\hold, value);
  };
  
  fork {
    "\n=== HOLD THRESHOLD DEMONSTRATION ===".postln;
    "Hold threshold: 0.4".postln;
    "Attack: 3s, Release: 3s\n".postln;
    
    // Phase 1: Below hold
    "Phase 1: SetPressure(0.2) - below hold".postln;
    ~setPressure.value(0.2);
    4.wait;
    "Amp should be at 0.2".postln;
    
    // Phase 2: Rise above hold
    "\nPhase 2: SetPressure(0.7) - crossing hold".postln;
    ~setPressure.value(0.7);
    4.wait;
    "Amp rising, passed 0.4 hold threshold".postln;
    "HOLD NOW ENGAGED".postln;
    
    // Phase 3: Try to drop below hold
    "\nPhase 3: SetPressure(0.2) - trying to go below hold".postln;
    ~setPressure.value(0.2);
    4.wait;
    "Amp should clamp at 0.4 (cannot go below hold!)".postln;
    
    // Phase 4: Set pressure to zero
    "\nPhase 4: SetPressure(0) - zero pressure".postln;
    ~setPressure.value(0);
    4.wait;
    "Amp stays at 0.4 (hold is sticky)".postln;
    
    // Phase 5: Lower hold threshold
    "\nPhase 5: SetHold(0.1) - lowering hold".postln;
    ~setHold.value(0.1);
    4.wait;
    "Amp can now fall to new hold (0.1)".postln;
    
    "\n=== DEMONSTRATION COMPLETE ===".postln;
    ~voice.free;
  };
});
)

// ====================================================================
// TEST 4: Harmonics Morphing (verify parameter changes work)
// ====================================================================
(
"=== TEST 4: Harmonics Morphing ===".postln;
s.waitForBoot({
  ~voice = Synth(\yggVoice, [
    \out, 0,
    \freq, 220,
    \amp, 0.5,
    \pressure, 1.0,  // Start at full
    \hold, 0.0,
    \attack, 1,
    \release, 2,
    \harmonics, 0.0  // Start with sine
  ]);
  
  ~setPressure = { |value| ~voice.set(\pressure, value) };
  
  fork {
    "Playing sine wave...".postln;
    2.wait;
    
    "Morphing to square (harmonics=0.5)...".postln;
    ~voice.set(\harmonics, 0.5);
    2.wait;
    
    "Morphing to saw (harmonics=1.0)...".postln;
    ~voice.set(\harmonics, 1.0);
    2.wait;
    
    "Back to sine (harmonics=0.0)...".postln;
    ~voice.set(\harmonics, 0.0);
    2.wait;
    
    "Releasing...".postln;
    ~setPressure.value(0.0);
    3.wait;
    
    ~voice.free;
    "Harmonics test complete".postln;
  };
});
)

// ====================================================================
// TEST 5: Musical Phrase (like cleanroom example 4)
// ====================================================================
(
"=== TEST 5: Musical Phrase ===".postln;
s.waitForBoot({
  ~voice = Synth(\yggVoice, [
    \out, 0,
    \freq, 440,
    \amp, 0.5,
    \pressure, 0,
    \hold, 0.2,
    \attack, 2,
    \release, 4,
    \harmonics, 0.0
  ]);
  
  ~setPressure = { |value| ~voice.set(\pressure, value) };
  
  fork {
    var notes = [60, 64, 67, 72, 67, 64, 60];
    var pressures = [0.6, 0.7, 0.8, 0.9, 0.7, 0.6, 0.5];
    var durations = [1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 2.0];
    
    "\n=== MUSICAL PHRASE ===".postln;
    
    notes.do({ |note, i|
      var freq = note.midicps;
      
      "Note: % Pressure: %".format(note, pressures[i]).postln;
      ~voice.set(\freq, freq);
      ~setPressure.value(pressures[i]);
      
      durations[i].wait;
    });
    
    "Release".postln;
    ~setPressure.value(0);
    
    5.wait;
    "=== PHRASE COMPLETE ===".postln;
    ~voice.free;
  };
});
)

// ====================================================================
// TEST 6: Polyphonic (4 voices)
// ====================================================================
(
"=== TEST 6: Polyphonic Test ===".postln;
s.waitForBoot({
  var freqs = [220, 275, 330, 440];
  var holds = [0.2, 0.25, 0.3, 0.35];
  
  ~voices = freqs.collect({ |freq, i|
    Synth(\yggVoice, [
      \out, 0,
      \freq, freq,
      \amp, 0.4,  // Quieter for 4 voices
      \pressure, 0,
      \hold, holds[i],
      \attack, rrand(2, 5),
      \release, rrand(4, 8),
      \harmonics, 0.0
    ]);
  });
  
  ~setPressures = ~voices.collect({ |voice|
    { |value| voice.set(\pressure, value) }
  });
  
  fork {
    "\n=== POLYPHONIC CONTROL ===".postln;
    
    "Staggered swell".postln;
    ~voices.size.do({ |i|
      ~setPressures[i].value(rrand(0.5, 0.9));
      0.5.wait;
    });
    
    6.wait;
    
    "Staggered release".postln;
    ~voices.size.do({ |i|
      ~setPressures[i].value(0);
      0.5.wait;
    });
    
    8.wait;
    
    "=== POLYPHONIC TEST COMPLETE ===".postln;
    ~voices.do(_.free);
  };
});
)

// ====================================================================
// CLEANUP
// ====================================================================
(
if(~voice.notNil) { ~voice.free };
if(~voices.notNil) { ~voices.do(_.free) };
s.freeAll;
)
