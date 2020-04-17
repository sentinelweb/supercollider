s.plotTree
s.meter
(SynthDef (\env, {
	var sig,freq,env;
	env = XLine.kr(1,0.01,1,doneAction:2);
	freq = XLine.kr(880,110,5,doneAction:2);
	sig = Pulse.ar(freq)*env;
	Out.ar(0, sig);
}).add
)

y = Synth(\env)
y.free

s.boot

// freqs has a literal array of defaults. This makes a multichannel Control of the same size.
(
SynthDef(\arrayarg, { |out, amp = 0.1, freqs = #[300, 400, 500, 600], gate = 1|
    var env, sines;
    env = Linen.kr(gate, 0.1, 1, 1, 2) * amp;
    sines = SinOsc.ar(freqs +.t [0,0.5]).cubed.sum; // A mix of 4 oscillators
    Out.ar(out, sines * env);
}, [0, 0.1, 0]).add;
)

x = Synth(\arrayarg);
x.setn(\freqs, [440, 441, 442, 443]);
x.free

(SynthDef(\multi, {
	var sig, amp, env;
	env = EnvGen.kr(
		Env.new([0,1,0], [10,10], [1,-1]),
		doneAction:2
	);
	amp = SinOsc.kr({ExpRand(0.2,12)}!8).range(0,1);
	sig = SinOsc.ar({ExpRand(50,12000)}!8);
	sig = sig * amp * env;
	sig = Splay.ar(sig) * 0.5;
	Out.ar(0,sig)

}	).add
)

z= Synth.new(\multi);
z.free