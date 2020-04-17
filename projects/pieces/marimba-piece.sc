// https://www.youtube.com/watch?v=lGs7JOOVjag&t=1664s
s.plotTree
(
~out = 0;
c = TempoClock.default;
c.tempo = 2; //120 bpm 4/4
)
///////////////// bpf saw - from tut - make marbima sounds /////////////////////////////
(
SynthDef(\bpfsaw, {
	arg pre=0,atk=2,sus=0,rel=3, c1=1, c2=(-1), freq=500, detune=0.2, pan=0, cfhzmin=0.1,cfhzmax=0.3, cfmin=500, cfmax=2000,rqmin=0.1, rqmax=0.2, lsf=200,ldb=0, amp=1;
	var sig, env;
	env= EnvGen.kr(Env([0,0,1,1,0],[pre,atk,sus,rel],[c1,0,c2]), doneAction:2);
	sig = Saw.ar(freq * {LFNoise1.kr(0.5, detune).midiratio}!2);
	sig = BPF.ar(sig,
		{
			LFNoise1.kr(
				LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)
		).exprange(cfmin, cfmax)}!2,
		{LFNoise1.kr(0.1).exprange(rqmin, rqmax)}!2
	);
	sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
	sig = Balance2.ar(sig[0],sig[1],pan);
	sig = sig * env * amp;
	Out.ar(~out, sig)
}).add;


/* ----------------------
   Synthetic bass drum
   ---------------------- */
SynthDef(\bass, {
	arg amp=0.5, dura =0.25, freq=50, metal = 1.1 ;
	var amp_env, phase_env, phase, sig;

	amp_env   = EnvGen.ar(Env.perc(1e-6,dura), doneAction:2);
	phase_env = EnvGen.ar(Env.perc(1e-6,0.125));

	phase = SinOsc.ar(20,0,pi) * phase_env;
	sig = SinOsc.ar([freq,metal*freq],phase) * amp_env * amp;

	Out.ar(~out, sig);
}).add;

/* ----------------------
   Synthetic snare
   ---------------------- */
SynthDef(\snare, {
	arg amp=0.5, cut_freq = 3000, dura = 0.25;
	var amp_env, sig;

	amp_env = EnvGen.ar(Env.perc(1e-6, dura), doneAction:2);
	sig = LPF.ar( {WhiteNoise.ar(WhiteNoise.ar)}.dup * amp_env, cut_freq ) * amp;

	Out.ar(~out, sig);
}).add;


/* ----------------------
   Synthetic hi-hat
   ---------------------- */
SynthDef(\hat, {
	arg amp=0.5, cut_freq=6000, dura=0.25;

	var amp_env,sig  ;
	amp_env = EnvGen.ar(Env.perc(1e-7, dura), doneAction:2);
	sig = HPF.ar( {WhiteNoise.ar}.dup * amp_env, cut_freq ) * amp / 4;

	Out.ar(~out, sig);
}).add;
)


////////////////////// test synths ////////////////////////
~marimbaTest =  Synth.new(\bpfsaw,[\freq,2,\atk, 0,\rqmin, 0.0005,\rqmax, 0.008]);
~marimbaTest.free

(~marimbaSingleTest =  Synth.new(\bpfsaw,[\dur,1,\amp,5,\freq,400,\detune,0,
	\atk, 0,\rel,1,
	\rqmin, 0.0005,\rqmax, 0.008,
	\cfmin,200, \cfmax,1000
]);)
~marimbaSingleTest.free

~rollingBassTest = Synth.new(\bpfsaw,[\amp,10,\freq,30,\pre, 0.5, \atk,0.2,\sus,0.28,\rel:0.1,\rqmin, 0.05,\rqmax, 0.08,\cfhzmin,0,\cfhzmax,0,\cfmin,25,\cfmax,40]);
~rollingBassTest.free


~bassTest = Synth.new(\bass,[\amp,0.8,\freq,50 /* 20 bass - 200 tom*/, \dur, 0.8])
~glockTest = Synth.new(\bass,[\amp,0.8,\freq,1200]) // mid freq is glock 400-1800, high is triangle 2k-20k
~snareTest = Synth.new(\snare,[\amp,0.8,\cut_freq,1000 /* 200-20000*/, \dur, 0.2 /* 0.05 - 1 */])
~hatTest = Synth.new(\hat,[\amp,0.8,\cut_freq,4000 /* 2000 heavy - 20000 lightest*/, \dur, 0.8 /* 0.05 closed - 1 open */])

~freqScope = FreqScope.new(400, 200, 0, server: s);
////////////////////// sequencing ////////////////////////////////////////
(
Pdef(\bassline).quant = [c.beatsPerBar];
~introSequence = Ppar([
		Pbind(\instrument, \bass, \amp, 0.8, \freq, 20,       \dur, 2,  \dura, 0.6, \metal, 1.2),
		//Pbind(\instrument, \snare,\amp, 0.8, \cut_freq, 4000, \dur, 4,  \dura, 0.2),
		Pbind(\instrument, \hat,  \amp, 0.4, \cut_freq, 5000, \dur, 0.5, \dura, 0.2),
		Pbind(\instrument, \bass, \amp, 0.04, \freq, 10000, \dur, 8, \dura, 2),
		~marimbaIntro
	]);

~chorusSequence  = Ppar([
		Pbind(\instrument, \bass, \amp, 0.8, \freq, 20,       \dur, 1,  \dura, 0.3, \metal, 1.1),
		//Pbind(\instrument, \snare,\amp, 0.8, \cut_freq, 4000, \dur, 4,  \dura, 0.2),
		Pbind(\instrument, \hat,  \amp, 0.4, \cut_freq, 5000, \dur, 1, \dura, 0.2),
	Pbind(\instrument, \bass, \amp, 0.04, \freq, Prand((Scale.major.degrees+108).midicps,inf), \dur, 0.5, \dura, 0.5),
	// use bpfsaw for rolling bass w. sloping reverse envelopes and var blowshelf
	Pbind(\instrument,\bpfsaw,	\dur, 1,\amp,2.5,\freq,30,\pre, 0.5,
		\atk,0.2,\sus,0.28,\rel,0.1,
		\rqmin, 0.2,\rqmax, 0.3,\cfhzmin,0,\cfhzmax,0,
		\cfmin,25,\cfmax,40),
	Pbind(\instrument,\bpfsaw,\dur,0.5,\amp,3,\freq,400,\detune,0,
		\atk, 0,\rel,1,
		\rqmin, 0.0005,\rqmax, 0.008,
		\cfmin,200, \cfmax,1000),
	]);


Pdef(\bassline, // why does dur affect the rate?
	//~introSequence
	~chorusSequence
).play;
)
Pdef(\bassline).stop;

(
~marimba.stop;
~marimba = Pbind(
	\instrument,\bpfsaw,
	\dur, 4,//Pexprand(0.1,1,inf),
	\freq, 32,//Pexprand(8,9,inf),
	\detune, 0.5,
	\atk, 0.1, \sus, 1, \rel, 1,
	\rqmin, 0.005, \rqmaz, 0.008,
	//\cfmin, 150, \cfmax, 1500,
	\cfmin, Pseq([100,200,300,400],inf), \cfmax, Pkey(\cfmin),
	\amp, 0.001
).play;
)
~marimba.set(\freq,16);
~marimba.stop;

// really nice for an intro
~marimbaIntro = Pbind(
	\instrument,\bpfsaw,
	\dur, 1,//Pexprand(0.1,1,inf),
	\freq, 4,//Pexprand(8,9,inf),
	\detune, 0,
	\rqmin, 0.005, \rqmaz, 0.008,
	//\cfmin, 150, \cfmax, 1500,
	\cfmin, Pseq([100,200,300,400],inf), \cfmax, Pkey(\cfmin),
	\amp, 0.3,
	\out, 0
);

~marimbaIntroPlayer = ~marimbaIntro.play;
~marimbaIntroPlayer.stop;
/////////////////// test code ////////////////////////
// env curve
Env.perc(0.05, 1, 1, -4).test.plot;
Env.perc(0.001, 1, 1, -4).test.plot;    // sharper attack
Env.perc(0.001, 1, 1, -8).test.plot;    // change curvature
Env.perc(1, 0.01, 1, 4).test.plot;    // reverse envelope
