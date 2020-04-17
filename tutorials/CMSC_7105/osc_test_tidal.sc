(
SynthDef("mtest", { |out, ffreq = 100|
	Out.ar(out, SinOsc.ar(300, ffreq.scope))
}).add;
)

x = Synth("mtest");
x.set(\ffreq, 100)
x.trace;
x.free;
