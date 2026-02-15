// ====================================================================
// YGG TEST SCRIPTS
// Collection of test scripts for debugging the Ygg engine
// ====================================================================

// ====================================================================
// TEST 1: Minimal Envelope Test
// Tests basic EnvGen.ar with ADSR to verify SuperCollider works
// ====================================================================
(
"=== TEST 1: Minimal Envelope ===".postln;
~env = {
  var gate = \gate.kr(1);
  var env = EnvGen.ar(
    Env.adsr(0.5, 0.01, 1.0, 3.0),  // 0.5s attack, 3s release
    gate,
    doneAction: 2
  );
  
  gate.poll(10, "gate");
  env.poll(10, "env");
  
  SinOsc.ar(440) * env * 0.2 ! 2;
}.play;
)

// Release after 2 seconds
(
fork {
  2.wait;
  "=== Setting gate to 0 - should fade over 3 seconds ===".postln;
  ~env.set(\gate, 0);
}
)

// ====================================================================
// TEST 2: ARH Envelope Test  
// Tests the pressure-driven ARH (Attack-Release-Hold) envelope
// ====================================================================
(
"=== TEST 2: ARH Envelope ===".postln;
~arh = {
  var pressure = \pressure.kr(0);
  var hold = \hold.kr(0.3);
  var attackTime = 1.0;
  var releaseTime = 3.0;
  var amp, ampControl, holdState, pressureState;
  var targetAmp, rateControl, sig;
  
  // State machine
  amp = LocalIn.ar(1);
  holdState = K2A.ar(amp >= hold);
  targetAmp = Select.ar(holdState, [
    K2A.ar(pressure),
    K2A.ar(max(pressure, hold))
  ]);
  
  pressureState = K2A.ar(targetAmp > amp);
  rateControl = Select.ar(pressureState, [
    K2A.ar(releaseTime.reciprocal),
    K2A.ar(attackTime.reciprocal)
  ]);
  
  ampControl = Lag.ar(targetAmp, rateControl.reciprocal);
  LocalOut.ar(ampControl);
  
  // Monitor
  pressure.poll(10, "pressure");
  amp.poll(10, "amp");
  hold.poll(10, "hold");
  
  sig = SinOsc.ar(440) * ampControl * 0.2;
  sig ! 2;
}.play;
)

// Test sequence
(
fork {
  "Setting pressure to 1.0 (attack)...".postln;
  ~arh.set(\pressure, 1.0);
  3.wait;
  
  "Setting pressure to 0.0 (release to hold=0.3)...".postln;
  ~arh.set(\pressure, 0.0);
  4.wait;
  
  "Setting hold to 0.0 (should continue releasing)...".postln;
  ~arh.set(\hold, 0.0);
  4.wait;
  
  "Done".postln;
  ~arh.free;
}
)

// ====================================================================
// TEST 3: Ygg Basic Release Test
// Tests the full Ygg engine with release
// ====================================================================
(
"=== TEST 3: Ygg Basic Release ===".postln;
s.freeAll;
~ygg.free;
1.wait;

~ygg.init;
s.sync;

~ygg.setHold(0.0);
~ygg.setAllVoices(\attack, 0.5);
~ygg.setAllVoices(\release, 3.0);

"Settings: hold=%, defaultAttack=%, defaultRelease=%".format(
  ~ygg.hold, ~ygg.defaultAttack, ~ygg.defaultRelease
).postln;

fork {
  "Playing note 60...".postln;
  ~ygg.noteOn(60, 100);
  
  2.wait;
  
  "Releasing note 60 (should fade over 3 seconds)...".postln;
  ~ygg.noteOff(60);
  
  5.wait;
  "Should be silent now".postln;
};
)

// ====================================================================
// TEST 4: Ygg Harmonics Morphing Test
// Tests oscillator morphing (sine -> square -> saw)
// ====================================================================
(
"=== TEST 4: Ygg Harmonics ===".postln;
s.freeAll;
~ygg.free;
1.wait;

~ygg.init;
s.sync;

~ygg.setAllVoices(\attack, 0.5);
~ygg.setAllVoices(\release, 1.0);

fork {
  "Playing sine wave (harmonics=0)...".postln;
  ~ygg.setAllVoices(\harmonics, 0.0);
  ~ygg.noteOn(60, 100);
  2.wait;
  
  "Morphing to square (harmonics=0.5)...".postln;
  ~ygg.setAllVoices(\harmonics, 0.5);
  2.wait;
  
  "Morphing to saw (harmonics=1.0)...".postln;
  ~ygg.setAllVoices(\harmonics, 1.0);
  2.wait;
  
  ~ygg.noteOff(60);
  2.wait;
  "Done".postln;
};
)

// ====================================================================
// TEST 5: Ygg Cross-Modulation Test
// Tests routing changes (neighbor -> cross -> loop)
// ====================================================================
(
"=== TEST 5: Ygg Cross-Modulation ===".postln;
s.freeAll;
~ygg.free;
1.wait;

~ygg.init;
s.sync;

~ygg.setAllVoices(\modDepth, 0.5);

fork {
  "Playing 4 notes...".postln;
  [60, 64, 67, 71].do { |note|
    ~ygg.noteOn(note, 100);
    0.1.wait;
  };
  
  2.wait;
  "Routing: Neighbor (0)...".postln;
  ~ygg.setRouting(0);
  2.wait;
  
  "Routing: Cross (1)...".postln;
  ~ygg.setRouting(1);
  2.wait;
  
  "Routing: Loop (2)...".postln;
  ~ygg.setRouting(2);
  2.wait;
  
  [60, 64, 67, 71].do { |note|
    ~ygg.noteOff(note);
  };
  
  2.wait;
  "Done".postln;
};
)

// ====================================================================
// CLEANUP
// ====================================================================
(
s.freeAll;
~ygg.free;
)
