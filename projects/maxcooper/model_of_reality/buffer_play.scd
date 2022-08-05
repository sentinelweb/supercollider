// tempo: 105

// key: EMaj
(
~tempo = 105;
s.waitForBoot{
	s.plotTree;
	s.meter;
	Buffer.freeAll();
	~samples = Dictionary.new;
	// p6 tonalFX5, FX6 - good stuff
	~fileNames = (
		\lead : "Lead Chords - Dry (w:StFx).wav",
        \kick : "Kick + Tune.wav",
        \hat : "HiHat Sustain - Dry 7L .wav",
        \perc : "Perc FX 1 - Dry (w:StFx).wav",
        \vocal_5 : "Vocal Chops 5 (w:StFx).wav"
	);
	~folder = PathName.new("/Users/robmunro/Downloads/A Model of Reality remix challenge/A Model of Reality/Audio Files/");
	~counter = 0;
	~fileNames.keys.do({|fileKey|
		var path = ~folder.fullPath++~fileNames[fileKey];
		path.postln;
		~samples = ~samples.put(fileKey, Buffer.read(s, path));
		~counter = ~counter + 1;
	});
}
)

(
SynthDef(\dummy, { }).add;
SynthDef.new(\bufrd_trig, {
	arg amp=1, out=0, buf, seg=#[0, 2.285], pitchRatio, timeDispersion=0;// 2.285 = 4*60/105 = 4 beats
	var sig, ptr, env, start, length, startSamp, endSamp;

	start = seg[0]; length = seg[1];
	startSamp = start * BufSampleRate.ir(buf);
	endSamp = startSamp + (length * BufSampleRate.ir(buf));

	ptr = Line.ar(startSamp, endSamp, length, doneAction: 2);
	sig = BufRd.ar(2, buf, ptr, loop:0);

	sig = PitchShift.ar(sig, 0.01, pitchRatio, timeDispersion: timeDispersion);

	env = Env.new([0, 1, 1, 0], [0.02, 0.96, 0.02] * length, curve: [-4, 0, 4]);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	sig = sig * amp;
	Out.ar(out, sig);
}).add;
)

// sequencing ////////////////////////////////////
(
PdefAllGui();
~tempoClock = TempoClock.default;
~tempoClock.tempo = ~tempo/60;
~beatTime = 60/~tempo;
~seg = (
	lead:[
		[8.538, 4*~beatTime],
		[57.411, 4*~beatTime]
	],
	perc:[
	    [144.3, ~beatTime],
	    [199.22, ~beatTime],
	    [196.22, 2*~beatTime],
	],
	vocal_5:[
	    [42, 4*~beatTime],
	    [161, 4*~beatTime]
	]
);

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

