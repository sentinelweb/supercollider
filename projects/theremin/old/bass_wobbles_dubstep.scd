//https://sccode.org/1-5cS

( // if you like bass wobbles

SynthDef(\wobble, {
	arg out=0, wflo=1, wfhi=6, decay=0, gate=1, wfmax=8500, amp=0.5, freq, iphase;
	var env = Linen.kr(gate, releaseTime: 0.01, doneAction: Done.freeSelf);
	var son = MoogVCF.ar(
		in: (
			Pulse.ar([freq * 0.98, freq], mul:0.5) +
			PinkNoise.ar(LFNoise0.ar(2).range(0, 1.0)) +
			Saw.ar([freq, freq * 1.025], mul:2)
		).clip2(0.5),
		fco: LFCub.kr(
			freq:LFPulse.kr(0.25, iphase, width: 0.25).range(
				wflo, wfhi) ).exprange(40, wfmax),
		res: 0.4,
		mul:2
	);
	Out.ar(out, son * env * amp);
}).add;

b = Bus.audio(s,2);

SynthDef("delayBus", { | outBus = 0, inBus, wet = 0.4 |
	var input = In.ar(inBus,2);
	var rev = Greyhole.ar(input * wet,
		delayTime:0.5, feedback:0.5, diff:0.4,
		damp:0.5, modDepth:0.8, modFreq:0.3);
    Out.ar(outBus, input + rev);
}).play(s, [\inBus,b]);

// Pdef(\wobble,Pbind(
// 	\instrument, \wobble,
// 	\legato, 0.98, \out, b,
// 	\dur, 1,
// 	\amp, 0.1,
// 	\wflo, Prand([1,2,4],inf),
// 	\wfhi, Prand([4,6,8],inf),
// 	\wfmax, Pseq([4,6,3,1,9]*500,inf),
// 	\iphase, Prand([0,0.25,0.5,0.75], inf),
// 	\degree, Pseq([2,0,-2,-2], 1),
// 	\octave, 2,
// )).quant_(~tempoClock.beatsPerBar);

Pdef(\wobble,Pbind(
	\instrument, \wobble,
	\legato, 0.98, \out, b,
	\dur, 1,
	\amp, 0.1,
	\wflo, 1,
	\wfhi, 2,
	\wfmax, 1000,
	\iphase, 0.25,
	\degree, Pseq([-2,0,2,2], 1),
	\octave, 2,
)).quant_(~tempoClock.beatsPerBar);
)
Pdef(\wobble).play;
Pdef(\wobble).stop;
