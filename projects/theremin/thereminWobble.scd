
(
b = Bus.audio(s,2);
~thereminFreqBus = Bus.control(s,1);
SynthDef("delayBus", { | outBus = 0, inBus, wet = 0.4 |
	var input = In.ar(inBus,2);
	var rev = Greyhole.ar(input * wet,
		delayTime:0.5, feedback:0.5, diff:0.4,
		damp:0.5, modDepth:0.8, modFreq:0.3);
    Out.ar(outBus, input + rev);
}).play(s, [\inBus,b]);
)
(
SynthDef(\thereminFreq, {
	arg in=0, out=0;
	var sig, freq, hasFreq;
	sig = In.ar(in,1) ! 2;
	sig = HPF.ar(HPF.ar(sig, 100), 20);
    sig.scope();

	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);

    Out.kr(out, freq);
}).add;
)
(
// if you like bass wobbles
SynthDef(\wobble, {
	arg out=0, wflo=1, wfhi=6, decay=0, gate=1, wfmax=8500, freq, iphase, resonance=0.4,wobbleFreq = 0.25;
	var env = Linen.kr(gate, releaseTime: 0.01, doneAction: Done.freeSelf);
	var son = MoogVCF.ar(
		in: (
			Pulse.ar([freq * 0.98, freq], mul:0.5) +
			PinkNoise.ar(LFNoise0.ar(2).range(0, 1.0)) +
			Saw.ar([freq, freq * 1.025], mul:2)
		).clip2(0.5),
        fco: LFCub.kr(
            freq:LFPulse.kr(wobbleFreq, iphase, width: 0.25).range( wflo, wfhi)
        ).exprange(40, wfmax),
		res: resonance,
		mul:2
	);
	Out.ar(out, son * env);
}).add;
)
(
(~thereminWobble != nil).if {~thereminWobble.free;};
~thereminFreqInput = Synth(\thereminFreq,[\in, ~thereminBus, \out, ~thereminFreqBus]);
~tempo = 128;
(~thereminWobble != nil).if {~thereminWobble.free;};
~thereminWobble = Synth(\wobble,[
	\out, b,
	\legato, 0.98,
	\wflo, ~tempo / 60,//Prand([1,2,3],inf),// change these to match tempo
	\wfhi, ~tempo / 60 * 4,//Prand([4,6,8],inf),
    \wobbleFreq, ~tempo / 60 / 4,
	\wfmax, 1000, //Pseq([4,6,3,1,9]*500,inf),
	\iphase, 0.75, //Prand([0,0.25,0.5,0.75], inf),
	\degree, 2, //Pseq([2, 2, -2, 2], 1),
	\freq, 37.midicps
]
);)
(
~thereminFreqInput.free;
~thereminWobble.free;
)
~thereminWobble.set(\gate,0);
~thereminWobble.set(\freq,36.midicps);
~thereminWobble.set(\resonance,0.8);
~thereminWobble.set(\freq,~thereminFreqBus);
// ~thereminWobble.play();

Pbind(
	\instrument, \wobble,
	\legato, 0.98, \out, b,
	\dur, 4,
	\wflo, Prand([1,2,3],inf),
	\wfhi, Prand([4,6,8],inf),
	\wfmax, Pseq([4,6,3,1,9]*500,inf),
	\iphase, Prand([0,0.25,0.5,0.75], inf),
	\degree, Pseq([2], 1),
	\octave, 2,
).play;