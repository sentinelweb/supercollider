// https://www.youtube.com/watch?v=lGs7JOOVjag&t=1664s
s.plotTree
(
~out = 0;
)

(
SynthDef(\bpfsaw, {
	arg atk=2,sus=0,rel=3, c1=1, c2=(-1), freq=500, detune=0.2, pan=0, cfhzmin=0.1,cfhzmax=0.3, cfmin=500, cfmax=2000,rqmin=0.1, rqmax=0.2, lsf=200,ldb=0, amp=1;
	var sig, env;
	env= EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]), doneAction:2);
	sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}!2);
	sig = BPF.ar(sig,
		{LFNoise1.kr(
			LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)
		).exprange(cfmin, cfmax)}!2,
		{LFNoise1.kr(0.1).exprange(rqmin, rqmax)}!2
	);
	sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
	sig = Balance2.ar(sig[0],sig[1],pan);
	sig = sig * env * amp;
	Out.ar(~out, sig)
}).add;
)

( Synth.new(\bpfsaw,[
	\freq,2,
	\atk, 0,
	\rqmin, 0.0005,
	\rqmax, 0.008
]
);
)

(
~marimba = Pbind(
	\instrument,\bpfsaw,
	\dur, 1,//Pexprand(0.1,1,inf),
	\freq, 4,//Pexprand(8,9,inf),
	\detune, 0,
	\rqmin, 0.005, \rqmaz, 0.008,
	//\cfmin, 150, \cfmax, 1500,
	\cfmin, Pseq([100,200,300,400],inf), \cfmax, Pkey(\cfmin),
	\amp, 0.001
).play;
)
~marimba.setn(\freq,16)
~marimba.stop;

// really nice for an intro
(
~marimba = Pbind(
	\instrument,\bpfsaw,
	\dur, 1,//Pexprand(0.1,1,inf),
	\freq, 4,//Pexprand(8,9,inf),
	\detune, 0,
	\rqmin, 0.005, \rqmaz, 0.008,
	//\cfmin, 150, \cfmax, 1500,
	\cfmin, Pseq([100,200,300,400],inf), \cfmax, Pkey(\cfmin),
	\amp, 0.01,
	\out, 0
).play;
)