// tempo: 105

// key: EMaj
(
~tempo = 105;
// just when using beats heaphones - input sr 16k
s.options.numInputBusChannels=0;
s.waitForBoot{
	s.plotTree;
	s.meter;
	Buffer.freeAll();
	~samples = Dictionary.new;
	// p6 tonalFX5, FX6 - good stuff
	~fileNames = (
		\lead : "Lead Chords - Dry (w:StFx).wav",
        \kick : "Kick + Tune.wav",
        \hat : "HiHat Sustain 2 - Dry.wav",
        \perc : "Perc FX 1 - Dry (w:StFx).wav",
        \vocal_5 : "Vocal Chops 5 (w:StFx).wav"
	);
	~folder = PathName.new("/Users/robmunro/Downloads/A Model of Reality remix challenge/A Model of Reality/Audio Files/");
	~counter = 0;
	~fileNames.keys.do({|fileKey|
		var path = ~folder.fullPath++~fileNames[fileKey];
		[path].postln;
		~samples = ~samples.put(fileKey, Buffer.read(s, path));
		~counter = ~counter + 1;
	});
}
)

(
SynthDef(\dummy, { }).add;
SynthDef.new(\bufrd_trig, {
	arg amp=1, out=0, buf, seg=#[0, 2.285], pitchRatio=#[1,1], timeDispersion=0;// 2.285 = 4*60/105 = 4 beats
	var sig, ptr, env, start, length, startSamp, endSamp, durSamp;

	durSamp = BufDur.ir(buf)*BufSampleRate.ir(buf);
	start = seg[0]; length = seg[1];
	startSamp = start * BufSampleRate.ir(buf);
	endSamp = startSamp + (length * BufSampleRate.ir(buf));
	ptr = Line.ar(startSamp, endSamp, length, doneAction: 2);
	sig  = if (pitchRatio[1],
		BufRd.ar(2, buf, ptr, loop:0) * 0.55,
		Warp1.ar(2, buf, ptr/durSamp, pitchRatio[0], windowSize:0.1, envbufnum:-1/*hanning*/, overlaps: 32, windowRandRatio:timeDispersion, interp:4, mul: 0.3)
	);
	env = Env.new([0, 1, 1, 0], [0.02, 0.96, 0.02] * length, curve: [-4, 0, 4]);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	sig = sig * amp;
	Out.ar(out, sig);
}).add;
)

// sequencing ////////////////////////////////////
(
s.plotTree;
PdefAllGui();
~tempoClock = TempoClock.default;
~tempoClock.tempo = ~tempo/60;
~beatTime = 60/~tempo;
~seg = (
	lead:[
		[[8.538, 4*~beatTime]],
		[[57.411, 4*~beatTime]],
		[[91.49, 4*~beatTime]],
//		[[316.75, 4*~beatTime]],// crackly
//		[[341.75, 4*~beatTime]],// crackly
	],
	perc:[
	    [[144.3, ~beatTime]],
	    [[199.22, ~beatTime]],
	    [[196.22, 2*~beatTime]],
	],
	vocal_5:[
	    [[42, 2*~beatTime]],
	    [[42, 4*~beatTime]],
	    [[161, 4*~beatTime]]
	],
	hats:[
	    [[82.38, 4*~beatTime]],
	    [[106.10, 4*~beatTime]],
	    [[235.08, 4*~beatTime]],
		[[262.96, 4*~beatTime]]
	],
	kick:[
	    [[41.09, 4*~beatTime]],
	    [[82.17, 4*~beatTime]],
	    [[201.0, 4*~beatTime]],
		[[217.0, 4*~beatTime]]
	]
);
~pitchRatio = {
	arg pitchRatio;
	[[pitchRatio.midiratio, if ((pitchRatio==0.0), 1, 0)]].postln;
};
)
~pitchRatio.(0)
// TODOS:
// - try finding a VST for pitchshift
// https://hiphopmakers.com/best-free-pitch-shifter-vst-plugins
// - make samp time variabe so just mod /dur
// try
// #[seg, sustain]:    Ptuple([
// 	Pfunc({~seg[\lead].choose}),
// 	Pkey(\dur, inf)
// ])

// - try making a Pattern of Pbind
// Pseq([
// 	Pbind(\instrument, \acid,
// 		\dur, Pseq([0.25, 0.5, 0.25], 4),
// 		\root, -24,
// 		\degree, Pseq([0, 3, 5, 7, 9, 11, 5, 1], inf),
// 		\pan, Pfunc({1.0.rand2}),
// 		\cut, Pxrand([1000, 500, 2000, 300], inf),
// 		\rez, Pfunc({0.7.rand +0.3}),
// 		\amp, 0.2
// 	),
// 	Pbind(\instrument, \acid,
// 		\dur, Pseq([0.25], 6),
// 		\root, -24,
// 		\degree, Pseq([18, 17, 11, 9], inf),
// 		\pan, Pfunc({1.0.rand2}),
// 		\cut, 1500,
// 		\rez, Pfunc({0.7.rand +0.3}),
// 		\amp, 0.16
// 	)
// ], inf).play;

(
Pdef(\lead_chords, Pbind(
	\instrument, \bufrd_trig,
	\amp, 0.5,
	\dur, 4,
	\buf, ~samples[\lead].bufnum,
	\seg, Pfunc({~seg[\lead].choose}),
	// \seg, Pfunc({~seg[\lead][2]}),
	\pitchRatio, Pfunc({~pitchRatio.(0)}),
	\timeDispersion, 0,
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)
(
Pdef(\perc, Pbind(
	\instrument, \bufrd_trig,
	\amp, 1,
	\dur, 2,
	\buf, ~samples[\perc].bufnum,
	\seg, Pfunc({~seg[\perc].choose}),
	\pitchRatio, Pfunc({~pitchRatio.(0)}),
	\timeDispersion, 0,
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)
(
Pdef(\vocal_5, Pbind(
	\instrument, \bufrd_trig,
	\amp, 1.5,
	\dur, 4,
	\buf, ~samples[\vocal_5].bufnum,
//	\seg, Pfunc({~seg[\vocal_5].choose}),
	\seg, Pfunc({~seg[\vocal_5][1]}),
	\pitchRatio, Pfunc({~pitchRatio.(2)}),
	\timeDispersion, 0.8,
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)
(
Pdef(\hats, Pbind(
	\instrument, \bufrd_trig,
	\amp, 1,
	\dur, 4,
	\buf, ~samples[\hat].bufnum,
	\seg, Pfunc({~seg[\hats].choose}),
	\pitchRatio, Pfunc({~pitchRatio.(0)}),
	\timeDispersion, 0,
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)
(
Pdef(\kick, Pbind(
	\instrument, \bufrd_trig,
	\amp, 1,
	\dur, 4,
	\buf, ~samples[\kick].bufnum,
	\seg, Pfunc({~seg[\kick].choose}),
	\pitchRatio, Pfunc({~pitchRatio.(0)}),
	\timeDispersion, 0,
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)
//control //////////////////////
Pdef(\lead_chords).play;
Pdef(\perc).play;
Pdef(\vocal_5).play;
Pdef(\lead_chords).stop;
Pdef(\perc).stop;
Pdef(\vocal_5).stop;
~state[\lead][\pitchRatio] = 4.midiratio
~state[\lead][\timeDispersion] = 0.001
~state[\vocal_5][\pitchRatio] = 5.midiratio
~state[\vocal_5][\timeDispersion] = 0.000
///////////////////////////////////////////////////////////////////////////
// pdef with state
(
~state = (
	lead:(
		amp: 1,
		seg: 1,
		pitchRatio: 1,
		timeDispersion: 0
	),
	perc:(
		amp: 1,
		seg: 1,
		pitchRatio: 1,
		timeDispersion: 0
	),
	vocal_5:(
		amp: 5,
		seg: 0,
		pitchRatio: 1,
		timeDispersion: 0
	)
);

// need seqr or a way to pass data to ~state
Pdef(\compose, Pmono(
	\dummy,
	\lead_seg, Pseq([0, 1, 0, 0, 1, 1, 0, 1], inf),
	\perc_seg, Pseq([0, 0, 0, 1, 2, 1, 1, 2], inf),
	\vocal_seg, Pseq([0, 0, 0, 1, 0, 0, 1, 1], inf),
	\dur, 2
)).quant_(~tempoClock.beatsPerBar);

Pdef(\lead_chords, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~state[\lead][\amp]}),
	\dur, 4,
	\buf, ~samples[\lead].bufnum,
	\seg, Pfunc({~seg[\lead][~state[\lead][\seg]]}),
	\pitchRatio, Pfunc({~state[\lead][\pitchRatio]}),
	\timeDispersion, Pfunc({~state[\lead][\timeDispersion]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);

Pdef(\perc, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~state[\perc][\amp]}),
	\dur, 8,
	\buf, ~samples[\perc].bufnum,
	\seg, Pfunc({~seg[\perc][~state[\perc][\seg]]}),
	\pitchRatio, Pfunc({~state[\perc][\pitchRatio]}),
	\timeDispersion, Pfunc({~state[\perc][\timeDispersion]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);

Pdef(\vocal_5, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~state[\vocal_5][\amp]}),
	\dur, 4,
	\buf, ~samples[\vocal_5].bufnum,
	\seg, Pfunc({~seg[\vocal_5][~state[\vocal_5][\seg]]}),
	\pitchRatio, Pfunc({~state[\vocal_5][\pitchRatio]}),
	\timeDispersion, Pfunc({~state[\vocal_5][\timeDispersion]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)


// jamming with raw loops ////////////////////////////////////
~samples[2].query;
x = Synth.new(\bufrd_trig, [\buf, ~samples[2].bufnum, \start, 44100*10,\end, 44100*11])
x.set(\rate, -0.midiratio);
x.set(\pitchRatio, 7.midiratio);
x.set(\timeDispersion, 0.02);
x.set(\start, 44100*10.0, \end, 44100*11);
x.set(\amp, 0.5);
x.free;

y = Synth.new(\bufrd_loop, [\buf, ~samples[3].bufnum, \start, 44100*144.3,\end, 44100*145.3])
y.set(\pitchRatio, 5.midiratio);
y.set(\rate, 0.5);
y.set(\amp, 1.8);
y.free;

z = Synth.new(\bufrd_loop, [\buf, ~samples[10].bufnum, \start, 44100*42,\end, 44100*43])
z.set(\rate, 2);
z.set(\timeDispersion, 0.1);
z.set(\start, 44100*10.0, \end, 44100*11);
z.set(\amp, 2);
z.free;
~samples[3].sampleRate
///////////////////////////////////////////// testing ///////////////////////
~player = ~samples[2].play;
~player.free;

~b0 = Buffer.read(s, "/Users/robmunro/Downloads/A Model of Reality remix challenge/A Model of Reality/Audio Files/Lead Chords - Dry (w:StFx).wav")


~x = ~b0.play;
~b0.stop;
~x.free;
Buffer.freeAll();


s.options.numBuffers;

440.cpsmidi
63.midicps

l=5;
Env.new([0, 1, 1, 0], [0.02, 0.96, 0.02] * l,curve: [-4, 0, 4]).plot;

