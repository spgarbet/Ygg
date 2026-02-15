// CleanroomEnvelope.sc
// State-based envelope system with hold threshold
//
// The voice is always on, starting at amplitude zero.
// State transitions are triggered by pressure requests and hold threshold crossings.
//
// States are defined by the relationship between:
//   - pressure: target amplitude (0.0 to 1.0)
//   - amp: current amplitude
//   - hold: threshold that once crossed from below, cannot fall below

(
SynthDef(\cleanroomVoice,
{
  |out = 0, freq = 440, pressure = 0, hold = 0.3, attackTime = 10, releaseTime = 10|
  
  var sig, amp, ampControl;
  var holdState, pressureState;
  var targetAmp, rateControl;
  
  // State machine for amplitude control
  // The envelope responds to pressure requests while respecting the hold threshold
  
  // Initialize amplitude at zero
  amp = LocalIn.ar(1);
  
  // Determine the target amplitude based on current state
  // Once amp crosses above hold, it cannot fall below hold
  holdState = K2A.ar(amp >= hold);
  targetAmp = Select.ar(holdState, [
    K2A.ar(pressure),              // Below hold: follow pressure directly
    K2A.ar(max(pressure, hold))    // Above hold: clamp to hold minimum
  ]);
  
  // Calculate appropriate slew rate based on direction
  // Rising: use attack time
  // Falling: use release time
  pressureState = K2A.ar(targetAmp > amp);
  rateControl = Select.ar(pressureState, [
    K2A.ar(releaseTime.reciprocal),  // Falling
    K2A.ar(attackTime.reciprocal)    // Rising
  ]);
  
  // Smooth amplitude transitions
  ampControl = Lag.ar(targetAmp, rateControl.reciprocal);
  
  // Feed back the amplitude for next sample
  LocalOut.ar(ampControl);
  
  // Generate the audio signal
  sig = SinOsc.ar(freq, 0, ampControl);
  
  // Output stereo
  Out.ar(out, sig ! 2);
}).add;
)
