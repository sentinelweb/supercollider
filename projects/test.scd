(
SynthDef(\test, {
	arg out=0, amp=0.005;
	var sig;
	sig = amp * SinOsc.ar(440);
	Out.ar(out, sig);
}).add;

~testSynth = Synth(\test,[\out,0]);
)
~testSynth.free;


// todo
// make a tool to listen to all input ports of a sound device and display a scope (so i can see all the inputs at once)