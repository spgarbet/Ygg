// ====================================================================
// YGG MANAGER DEBUG TEST
// Tests the manager to find why noteOff doesn't work
// ====================================================================

// Load manager first
(
thisProcess.nowExecutingPath.dirname +/+ "ygg_manager.scd".load;
)

// Initialize
(
~ygg.free;
s.freeAll;
1.wait;
~ygg.init;
s.sync;
"Ygg initialized".postln;
)



// ====================================================================
// DEBUG TEST: Trace noteOn/noteOff
// ====================================================================
(
fork {
  "=== DEBUG: Manager noteOn/noteOff ===".postln;

  // Set simple parameters
  ~ygg.setHold(0.0);
  ~ygg.setAllVoices(\attack, 1.0);
  ~ygg.setAllVoices(\release, 3.0);

  1.wait;

  "Calling noteOn(60, 100)...".postln;
  ~ygg.noteOn(60, 100);

  1.wait;

  // Get the voice
  ~voiceNum = ~ygg.activeNotes[60];
  ~voice = ~ygg.voices[~voiceNum];
  "Voice: %, VoiceNum: %".format(~voice, ~voiceNum).postln;
  "Voice isPlaying: %".format(~voice.isPlaying).postln;

  2.wait;
  "Note should be at full volume now".postln;

  1.wait;

  "Calling noteOff(60)...".postln;
  ~ygg.noteOff(60);

  "Checking voice after noteOff...".postln;
  "Voice isPlaying: %".format(~voice.isPlaying).postln;
  "Voice still in activeNotes: %".format(~ygg.activeNotes[60]).postln;

  1.wait;
  "Should be releasing now...".postln;

  3.wait;
  "Should be silent now".postln;
  "Voice isPlaying: %".format(~voice.isPlaying).postln;

  1.wait;
  "Test complete".postln;
};
)

// ====================================================================
// DEBUG TEST: Manual pressure control via manager
// ====================================================================
(
fork {
  "=== DEBUG: Manual pressure control ===".postln;

  s.freeAll;
  ~ygg.free;
  1.wait;
  ~ygg.init;
  s.sync;

  ~ygg.setHold(0.0);
  ~ygg.setAllVoices(\attack, 1.0);
  ~ygg.setAllVoices(\release, 3.0);

  1.wait;

  "Creating note...".postln;
  ~ygg.noteOn(60, 100);

  2.wait;
  "Note at full volume".postln;

  "Manually setting pressure to 0.5 via setPressure...".postln;
  ~ygg.setPressure(60, 0.5);

  2.wait;
  "Should be at half volume".postln;

  "Setting pressure to 0.0...".postln;
  ~ygg.setPressure(60, 0.0);

  4.wait;
  "Should be silent now".postln;

  ~ygg.free;
};
)

// ====================================================================
// DEBUG TEST: Check if setAllVoices interferes
// ====================================================================
(
fork {
  "=== DEBUG: setAllVoices interference test ===".postln;

  s.freeAll;
  ~ygg.free;
  1.wait;
  ~ygg.init;
  s.sync;

  ~ygg.setHold(0.0);
  ~ygg.setAllVoices(\attack, 1.0);
  ~ygg.setAllVoices(\release, 3.0);

  1.wait;

  "Creating note...".postln;
  ~ygg.noteOn(60, 100);

  2.wait;

  "Calling noteOff...".postln;
  ~ygg.noteOff(60);

  0.5.wait;

  "Calling setAllVoices (should NOT affect pressure)...".postln;
  ~ygg.setAllVoices(\harmonics, 0.5);

  4.wait;
  "Should be silent now (if setAllVoices doesn't interfere)".postln;

  ~ygg.free;
};
)

// ====================================================================
// DEBUG TEST: Multiple notes
// ====================================================================
(
fork {
  "=== DEBUG: Multiple notes ===".postln;

  s.freeAll;
  ~ygg.free;
  1.wait;
  ~ygg.init;
  s.sync;

  ~ygg.setHold(0.0);
  ~ygg.setAllVoices(\attack, 1.0);
  ~ygg.setAllVoices(\release, 3.0);

  1.wait;

  "Playing 3 notes...".postln;
  ~ygg.noteOn(60, 100);
  0.2.wait;
  ~ygg.noteOn(64, 100);
  0.2.wait;
  ~ygg.noteOn(67, 100);

  2.wait;

  "Releasing first note (60)...".postln;
  ~ygg.noteOff(60);

  2.wait;
  "Note 60 should be fading, others still playing".postln;

  "Releasing other notes...".postln;
  ~ygg.noteOff(64);
  ~ygg.noteOff(67);

  4.wait;
  "All should be silent now".postln;

  ~ygg.free;
};
)

// ====================================================================
// DEBUG TEST: Check actual synth node
// ====================================================================
(
fork {
  "=== DEBUG: Direct synth node inspection ===".postln;

  s.freeAll;
  ~ygg.free;
  1.wait;
  ~ygg.init;
  s.sync;

  ~ygg.setHold(0.0);

  1.wait;

  ~ygg.noteOn(60, 100);
  ~voiceNum = ~ygg.activeNotes[60];
  ~voice = ~ygg.voices[~voiceNum];

  "Voice synth: %".format(~voice).postln;

  2.wait;

  "Calling noteOff...".postln;
  ~ygg.noteOff(60);

  "Manually verifying with direct .set call...".postln;
  0.1.wait;
  ~voice.set(\pressure, 0.0);
  "Called .set(\\pressure, 0.0) directly on synth".postln;

  4.wait;
  "Did that work?".postln;

  ~ygg.free;
};
)

// ====================================================================
// CLEANUP
// ====================================================================
(
~ygg.free;
s.freeAll;
)
