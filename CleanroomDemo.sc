// CleanroomDemo.sc
// Demo code for the Cleanroom state-based envelope system
//
// Load the CleanroomEnvelope.sc file first before running these examples

// =============================================================================
// BASIC VOICE CONTROL WITH SETPRESSURE AND SETHOLD
// =============================================================================

// Example 1: Create a voice and control it with SetPressure
(
s.waitForBoot(
{
  // Create the voice
  ~voice = Synth(\cleanroomVoice, [
    \freq, 440,
    \pressure, 0,
    \hold, 0.3,
    \attackTime, 10,
    \releaseTime, 10
  ]);
  
  // Define SetPressure routine
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
    postln("SetPressure: " ++ value);
  };
  
  // Define SetHold routine
  ~setHold = 
  {
    |value|
    ~voice.set(\hold, value);
    postln("SetHold: " ++ value);
  };
  
  postln("Voice created. Use ~setPressure.value(0.0-1.0) and ~setHold.value(0.0-1.0)");
});
)

// Try these commands:
~setPressure.value(0.5);   // Request amplitude of 0.5
~setPressure.value(0.8);   // Increase to 0.8
~setPressure.value(0.1);   // Try to decrease (will clamp to hold if crossed)
~setPressure.value(0);     // Request zero amplitude

// Change the hold threshold
~setHold.value(0.5);       // Raise the hold threshold
~setHold.value(0.2);       // Lower the hold threshold

// Change frequency
~voice.set(\freq, 880);

// Free the synth
~voice.free;


// =============================================================================
// DEMONSTRATION OF HOLD THRESHOLD BEHAVIOR
// =============================================================================

// Example 2: Automated demonstration of state transitions
(
s.waitForBoot(
{
  ~voice = Synth(\cleanroomVoice, [
    \freq, 330,
    \pressure, 0,
    \hold, 0.4,
    \attackTime, 5,
    \releaseTime, 5
  ]);
  
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
  };
  
  ~setHold = 
  {
    |value|
    ~voice.set(\hold, value);
  };
  
  // Automated demonstration routine
  fork
  {
    postln("\n=== CLEANROOM ENVELOPE DEMONSTRATION ===");
    postln("Hold threshold: 0.4");
    postln("Attack time: 5s, Release time: 5s\n");
    
    // Phase 1: Below hold threshold
    postln("Phase 1: SetPressure(0.2) - below hold");
    ~setPressure.value(0.2);
    3.wait;
    postln("  Amp rising toward 0.2...");
    2.wait;
    
    // Phase 2: Drop pressure while below hold
    postln("\nPhase 2: SetPressure(0.1) - still below hold");
    ~setPressure.value(0.1);
    3.wait;
    postln("  Amp falling toward 0.1 (can fall freely below hold)");
    2.wait;
    
    // Phase 3: Rise above hold threshold
    postln("\nPhase 3: SetPressure(0.7) - crossing hold threshold");
    ~setPressure.value(0.7);
    2.wait;
    postln("  Amp rising...");
    2.wait;
    postln("  Amp passing 0.4 (hold threshold)...");
    2.wait;
    postln("  HOLD ENGAGED - cannot fall below 0.4 now");
    2.wait;
    
    // Phase 4: Try to drop below hold
    postln("\nPhase 4: SetPressure(0.2) - attempting to go below hold");
    ~setPressure.value(0.2);
    2.wait;
    postln("  Target is 0.2, but hold is 0.4");
    2.wait;
    postln("  Amp clamped to 0.4 - cannot fall below hold!");
    2.wait;
    
    // Phase 5: Set pressure to zero
    postln("\nPhase 5: SetPressure(0) - zero pressure request");
    ~setPressure.value(0);
    2.wait;
    postln("  Pressure is 0, but amp stays at hold (0.4)");
    2.wait;
    postln("  Hold is 'sticky' - once crossed, it persists");
    2.wait;
    
    // Phase 6: Change hold threshold
    postln("\nPhase 6: SetHold(0.2) - lowering hold threshold");
    ~setHold.value(0.2);
    2.wait;
    postln("  New hold: 0.2, pressure still 0");
    postln("  Amp can now fall to new hold level (0.2)");
    4.wait;
    
    postln("\n=== DEMONSTRATION COMPLETE ===");
  };
});
)

// Clean up
~voice.free;


// =============================================================================
// STATE TRANSITION TESTING
// =============================================================================

// Example 3: Test all state transitions from the specification
(
s.waitForBoot(
{
  ~voice = Synth(\cleanroomVoice, [
    \freq, 440,
    \pressure, 0,
    \hold, 0.5,
    \attackTime, 2,
    \releaseTime, 2
  ]);
  
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
  };
  
  ~setHold = 
  {
    |value|
    ~voice.set(\hold, value);
  };
  
  fork
  {
    postln("\n=== STATE TRANSITION TESTS ===");
    postln("Hold: 0.5\n");
    
    // PPAH: Pressure < Amp < Hold
    postln("Test PPAH: Pressure(0.2) < Amp(rising) < Hold(0.5)");
    ~setPressure.value(0.3);
    2.5.wait;
    ~setPressure.value(0.2);
    postln("  Amp should fall toward pressure (0.2)");
    3.wait;
    
    // PAHP: Amp < Hold < Pressure
    postln("\nTest PAHP: Amp < Hold(0.5) < Pressure(0.8)");
    ~setPressure.value(0.8);
    postln("  Amp should rise, crossing hold threshold");
    5.wait;
    
    // PPHA: Pressure < Hold < Amp (hold clamps)
    postln("\nTest PPHA: Pressure(0.3) < Hold(0.5) < Amp");
    ~setPressure.value(0.3);
    postln("  Amp should clamp at hold (0.5), not follow pressure");
    3.wait;
    
    // PHPA: Hold < Pressure < Amp
    postln("\nTest PHPA: Hold(0.5) < Pressure(0.6) < Amp(0.8)");
    ~setPressure.value(0.6);
    postln("  Amp should fall toward pressure (0.6)");
    3.wait;
    
    // AHPA: Amp < Hold < Pressure with hold change
    postln("\nTest hold threshold change");
    ~setPressure.value(0.3);
    3.wait;
    ~setHold.value(0.2);
    postln("  SetHold(0.2) - lowering threshold");
    postln("  Amp can now fall to meet pressure");
    3.wait;
    
    postln("\n=== TESTS COMPLETE ===");
  };
});
)

~voice.free;


// =============================================================================
// INTERACTIVE CONTROL PATTERN
// =============================================================================

// Example 4: Musical phrasing with explicit pressure control
(
s.waitForBoot(
{
  ~voice = Synth(\cleanroomVoice, [
    \freq, 440,
    \pressure, 0,
    \hold, 0.2,
    \attackTime, 3,
    \releaseTime, 6
  ]);
  
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
  };
  
  ~setHold = 
  {
    |value|
    ~voice.set(\hold, value);
  };
  
  fork
  {
    var notes = [60, 64, 67, 72, 67, 64, 60];
    var pressures = [0.6, 0.7, 0.8, 0.9, 0.7, 0.6, 0.5];
    var durations = [1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 2.0];
    
    postln("\n=== MUSICAL PHRASE ===");
    
    notes.do(
    {
      |note, i|
      var freq = note.midicps;
      
      postln("Note: " ++ note ++ " Pressure: " ++ pressures[i]);
      ~voice.set(\freq, freq);
      ~setPressure.value(pressures[i]);
      
      durations[i].wait;
    });
    
    postln("Release");
    ~setPressure.value(0);
    
    4.wait;
    postln("=== PHRASE COMPLETE ===");
  };
});
)

~voice.free;


// =============================================================================
// DYNAMIC ENVELOPE SHAPING
// =============================================================================

// Example 5: Changing attack and release times
(
s.waitForBoot(
{
  ~voice = Synth(\cleanroomVoice, [
    \freq, 330,
    \pressure, 0,
    \hold, 0.25,
    \attackTime, 10,
    \releaseTime, 10
  ]);
  
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
  };
  
  fork
  {
    postln("\n=== ENVELOPE TIMING DEMO ===");
    
    postln("Slow attack (10s)");
    ~setPressure.value(0.7);
    11.wait;
    
    postln("Slow release (10s)");
    ~setPressure.value(0);
    11.wait;
    
    postln("\nChanging to fast attack/release");
    ~voice.set(\attackTime, 0.5);
    ~voice.set(\releaseTime, 0.5);
    
    postln("Fast attack (0.5s)");
    ~setPressure.value(0.8);
    1.wait;
    
    postln("Fast release (0.5s)");
    ~setPressure.value(0);
    2.wait;
    
    postln("=== TIMING DEMO COMPLETE ===");
  };
});
)

~voice.free;


// =============================================================================
// POLYPHONIC DEMONSTRATION
// =============================================================================

// Example 6: Multiple voices with independent envelopes
(
s.waitForBoot(
{
  var freqs = [220, 275, 330, 440];
  var holds = [0.2, 0.25, 0.3, 0.35];
  
  ~voices = freqs.collect(
  {
    |freq, i|
    Synth(\cleanroomVoice, [
      \freq, freq,
      \pressure, 0,
      \hold, holds[i],
      \attackTime, rrand(3, 8),
      \releaseTime, rrand(5, 12)
    ]);
  });
  
  // Create individual control routines
  ~setPressures = ~voices.collect(
  {
    |voice|
    {
      |value|
      voice.set(\pressure, value);
    };
  });
  
  fork
  {
    postln("\n=== POLYPHONIC CONTROL ===");
    
    // Stagger pressure increases
    postln("Staggered swell");
    ~voices.size.do(
    {
      |i|
      ~setPressures[i].value(rrand(0.4, 0.8));
      0.5.wait;
    });
    
    6.wait;
    
    // Stagger releases
    postln("Staggered release");
    ~voices.size.do(
    {
      |i|
      ~setPressures[i].value(0);
      0.5.wait;
    });
    
    8.wait;
    
    postln("=== POLYPHONIC DEMO COMPLETE ===");
  };
});
)

// Clean up
~voices.do(_.free);


// =============================================================================
// CONTINUOUS CONTROL PATTERN
// =============================================================================

// Example 7: Smooth pressure changes over time
(
s.waitForBoot(
{
  ~voice = Synth(\cleanroomVoice, [
    \freq, 440,
    \pressure, 0,
    \hold, 0.3,
    \attackTime, 5,
    \releaseTime, 5
  ]);
  
  ~setPressure = 
  {
    |value|
    ~voice.set(\pressure, value);
  };
  
  fork
  {
    var steps = 20;
    
    postln("\n=== CONTINUOUS PRESSURE SWEEP ===");
    
    postln("Rising sweep");
    steps.do(
    {
      |i|
      var pressure = i.linlin(0, steps - 1, 0, 0.9);
      ~setPressure.value(pressure);
      0.3.wait;
    });
    
    2.wait;
    
    postln("Falling sweep (will clamp at hold)");
    steps.do(
    {
      |i|
      var pressure = i.linlin(0, steps - 1, 0.9, 0);
      ~setPressure.value(pressure);
      0.3.wait;
    });
    
    2.wait;
    
    postln("=== SWEEP COMPLETE ===");
  };
});
)

~voice.free;

