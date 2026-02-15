// Initialize the engine
(
~ygg.init;
)

// Simple release test
(
~ygg.setHold(0.0);  // Full release
~ygg.setAllVoices(\release, 5.0);  // 5 second release
~ygg.noteOn(60, 100);
)

// Wait 2 seconds, then release and listen for 5-second fadeout
(
fork {
  2.wait;
  ~ygg.noteOff(60);
}
)


// Test if EnvGen responds to gate changes
(
~test = {
  var gate = \gate.kr(1);  // Control-rate parameter
  var env = EnvGen.ar(
    Env.asr(0.5, 1.0, 3.0),
    gate,
    doneAction: 2
  );
  var sig = SinOsc.ar(440) * env * 0.2;

  // Poll the gate and env values
  gate.poll(10, "gate");
  env.poll(10, "env");

  sig ! 2;
}.play;
)

// Wait 2 seconds then release
(
fork {
  2.wait;
  "Setting gate to 0...".postln;
  ~test.set(\gate, 0);

  5.wait;
  "Synth should have freed itself by now".postln;
}
)



// Test if EnvGen responds to gate changes
(
~test = {
  var gate = \gate.kr(1);  // Control-rate parameter
  var env = EnvGen.ar(
    Env.asr(0.5, 1.0, 3.0),
    gate,
    doneAction: 2
  );
  var sig = SinOsc.ar(440) * env * 0.2;

  // Poll the gate and env values
  gate.poll(10, "gate");
  env.poll(10, "env");

  sig ! 2;
}.play;
)

// Wait 2 seconds then release
(
fork {
  2.wait;
  "Setting gate to 0...".postln;
  ~test.set(\gate, 0);

  5.wait;
  "Synth should have freed itself by now".postln;
}
)
