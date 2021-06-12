(
SynthDef(\test, {
	arg out=0, amp=0.2;
	var sig;
	sig = amp * SinOsc.ar(440);
	Out.ar(out, sig);
}).add;

~testSynth = Synth(\test);
)
~testSynth.free;