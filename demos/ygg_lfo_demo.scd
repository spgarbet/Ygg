// ====================================================================
// YGG LFO DEMONSTRATION
// Shows all LFO modes and their use in delay and cross-modulation
// ====================================================================

(
thisProcess.nowExecutingPath.dirname +/+ "ygg_manager.scd".load;
)

(
fork {
  "=== YGG LFO DEMONSTRATION ===".postln;

  // Setup for clean listening
  ~ygg.setHold(0.0);
  ~ygg.setAllVoices(\attack, 0.5);
  ~ygg.setAllVoices(\release, 2.0);
  ~ygg.setAllVoices(\harmonics, 0.0);  // Pure sine
  ~ygg.setVibratoDepth(0.0);  // No vibrato

  // Play single sustained note for all demos
  "Playing sustained note (C4 - 60)...".postln;
  ~ygg.noteOn(60, 100);

  2.wait;

  // ================================================================
  // PART 1: LFO MODES WITH DELAY MODULATION
  // ================================================================
  "".postln;
  "=== PART 1: LFO Modes (Delay Time Modulation) ===".postln;
  "".postln;

  // Enable delay with LFO modulation
  ~ygg.setDelay(
   0.25,  // time1
    0.5,   // time2
    0.3,   // mod1 (30% modulation depth)
    0.3,   // mod2
    0.3,   // feedback
    0.6,   // mix (60% wet)
    0      // modType will change
  );

  "1. LFO Mode 0: Single (freqA only)".postln;
  ~ygg.setLFO(0.2, 0.5, 0);  // freqA=0.2Hz, freqB ignored
  5.wait;
  "   Slow, steady modulation at 0.2Hz".postln;

  2.wait;
  "2. LFO Mode 1: Sum (freqA + freqB)".postln;
  ~ygg.setLFO(0.2, 0.5, 1);  // Both frequencies combine
  5.wait;
  "   Complex pattern from summing 0.2Hz and 0.5Hz".postln;

  2.wait;
  "3. LFO Mode 2: Product (freqA * freqB)".postln;
  ~ygg.setLFO(0.2, 0.5, 2);  // Ring modulation of LFOs
  5.wait;
  "   Tremolo-like effect from multiplying the LFOs".postln;

  2.wait;
  "4. LFO Mode 3: Chaos (freqA * freqB feedback)".postln;
  ~ygg.setLFO(0.3, 0.7, 3);  // Non-repeating pattern
  5.wait;
  "   Unpredictable, evolving modulation".postln;

  // Turn off delay
  2.wait;
  ~ygg.setDelay(0.25, 0.5, 0.0, 0.0, 0.3, 0.0, 0);
  1.wait;

  // ================================================================
  // PART 2: LFO AS CROSS-MODULATION SOURCE
  // ================================================================
  "".postln;
  "=== PART 2: LFO as Cross-Modulation Source ===".postln;
  "Using LFO to modulate pitch via cross-mod system".postln;
  "".postln;

  // Note: The LFO bus feeds into the delay, not directly into voices.
  // For this demo, we'll show cross-mod with different routing modes instead.

  "Cross-modulation with different routing modes:".postln;
  "".postln;

  "1. Routing 0: Self-modulation (each pair modulates itself)".postln;
  ~ygg.setRouting(0);
  ~ygg.setAllVoices(\modDepth, 0.3);
  5.wait;
  "   Gentle self-feedback wobble".postln;

  2.wait;
  "2. Routing 0 with higher modDepth (0.8)".postln;
  ~ygg.setAllVoices(\modDepth, 0.8);
  5.wait;
  "   Stronger self-modulation".postln;

  2.wait;
  "3. Routing 1: Cross (pairs 1↔3, 2↔4)".postln;
  ~ygg.setRouting(1);
  ~ygg.setAllVoices(\modDepth, 0.5);
  5.wait;
  "   Different modulation pattern from cross-pairing".postln;

  2.wait;
  "4. Routing 2: Neighbor (pairs 1↔2, 3↔4)".postln;
  ~ygg.setRouting(2);
  5.wait;
  "   Adjacent pair modulation".postln;

  // ================================================================
  // PART 3: VARYING MOD DEPTH
  // ================================================================
  "".postln;
  "=== PART 3: Cross-Mod Depth Sweep ===".postln;
  "".postln;

  ~ygg.setRouting(0);  // Self-modulation

  "Sweeping modDepth from 0.0 to 1.0:".postln;
  10.do { |i|
    var depth = i.linlin(0, 9, 0.0, 1.0);
    "  modDepth = %".format(depth.round(0.1)).postln;
    ~ygg.setAllVoices(\modDepth, depth);
    1.5.wait;
  };

  "".postln;
  "Notice how modulation intensity increases with depth".postln;

  // ================================================================
  // PART 4: COMBINED LFO DELAY + CROSS-MOD
  // ================================================================
  2.wait;
  "".postln;
  "=== PART 4: Combined LFO Delay + Cross-Mod ===".postln;
  "".postln;

  "Chaos LFO on delay + Self-modulation:".postln;
  ~ygg.setLFO(0.3, 0.7, 3);  // Chaos mode
  ~ygg.setDelay(0.25, 0.5, 0.4, 0.4, 0.4, 0.7, 0);
  ~ygg.setAllVoices(\modDepth, 0.6);
  ~ygg.setRouting(0);

  8.wait;
  "Complex, evolving texture from both modulation sources".postln;

  // Cleanup
  2.wait;
  ~ygg.noteOff(60);
  3.wait;

  "".postln;
  "=== LFO DEMONSTRATION COMPLETE ===".postln;
  "".postln;
  "Summary:".postln;
  "- 4 LFO modes: Single, Sum, Product, Chaos".postln;
  "- LFO modulates delay times for spatial effects".postln;
  "- Cross-mod uses voice feedback for pitch modulation".postln;
  "- 3 routing modes change modulation topology".postln;
  "- modDepth controls cross-modulation intensity".postln;

  s.freeAll;
};
)
