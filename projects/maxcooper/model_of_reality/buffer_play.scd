(
s.waitForBoot{
	s.plotTree;
	s.meter;
	Buffer.freeAll();
	~samples = Dictionary.new;
	~fileNames = (
		\lead : "Lead Chords - Dry (w:StFx).wav",
        \kick : "Kick + Tune.wav",
        \hat : "HiHat Sustain - Dry 7L .wav",
        \perc : "Perc FX 1 - Dry (w:StFx).wav",
        \vocal : "Vocal Chops 5 (w:StFx).wav"
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

( // todo send length
SynthDef.new(\bufrd_trig, {
	arg amp=1, out=0, buf, start, end, rate=1, freq=330/*midi 64*/, timeDispersion=0, t_trig=0;
	var sig, ptr, pitchRatio = 1, env, length;
	length = (end - start) / BufSampleRate.ir(buf); // secs
	//pitchRatio = (freq/64.midicps).asInteger;
	//ptr = Phasor.ar(t_trig, BufRateScale.kr(buf) * rate, start, end);
	ptr = Line.ar(start, end, length, doneAction: 2);
	//ptr.scope;
	sig = BufRd.ar(2, buf, ptr, loop:0);
	env = Env.new([0, 1, 1, 0], [0.02, 0.96, 0.02] * length, curve: [-4, 0, 4]);
	sig = sig * EnvGen.ar(env, doneAction: 2);
	//sig = PitchShift.ar(sig, 0.3, pitchRatio, timeDispersion: timeDispersion);
	sig = sig * amp;
	//sig.scope;
	Out.ar(out, sig);
}).add;
)

// sequencing ////////////////////////////////////
(
PdefAllGui();
~tempoClock = TempoClock.default;
~tempoClock.tempo = 105/60;
~tempoRatio = 105/120;
~cmp = (
	lead:(
		amp:1,
		start: 44100*10,
		end: 44100*(10 + ~tempoRatio),
	),
	perc_fx1:(
		amp:1,
		start: 44100*144.3,
		end: 44100*(144.3 + ~tempoRatio),
	),
	vocal_chops_10:(
		amp:5,
		start: 44100*42,
		end: 44100*(42 + ~tempoRatio),
	)
);

Pdef(\lead_chords, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~cmp[\lead][\amp]}),
	\dur, 1,
	\midinote, 64,
	\buf, ~samples[\lead].bufnum,
	\start, Pfunc({~cmp[\lead][\start]}),
	\end, Pfunc({~cmp[\lead][\end]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);

Pdef(\perc_fx1, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~cmp[\perc_fx1][\amp]}),
	\dur, 1,
	\midinote, 64,
	\buf, ~samples[\perc].bufnum,
	\start, Pfunc({~cmp[\perc_fx1][\start]}),
	\end, Pfunc({~cmp[\perc_fx1][\end]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);

Pdef(\vocal_chops_10, Pbind(
	\instrument, \bufrd_trig,
	\amp, Pfunc({~cmp[\vocal_chops_10][\amp]}),
	\dur, 1,
	\midinote, 60,
	\buf, ~samples[\vocal].bufnum,
	\start, Pfunc({~cmp[\vocal_chops_10][\start]}),
	\end, Pfunc({~cmp[\vocal_chops_10][\end]}),
	\out, 0,
)
).quant_(~tempoClock.beatsPerBar);
)

//control //////////////////////
Pdef(\lead_chords).play;
Pdef(\perc_fx1).play;
Pdef(\vocal_chops_10).play;
Pdef(\lead_chords).stop;
Pdef(\perc_fx1).stop;
Pdef(\vocal_chops_10).stop;
// jamming with raw loops ////////////////////////////////////
~samples[2].query;
x = Synth.new(\bufrd_trig, [\buf, ~samples[2].bufnum, \start, 44100*10,\end, 44100*11])
x.set(\rate, -0.midiratio);
x.set(\t_trig, 1);
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
z.set(\freq, );
z.set(\timeDispersion, 0.1);
z.set(\start, 44100*10.0, \end, 44100*11);
z.set(\amp, 2);
z.free;
// p6 tonalFX5, FX6 - good stuff
~samples[3].sampleRate
///////////////////////////////////////////// testing ///////////////////////
~player = ~samples[2].play;
~player.free;

~b0 = Buffer.read(s, "/Users/robmunro/Downloads/A Model of Reality remix challenge/A Model of Reality/Audio Files/Lead Chords - Dry (w:StFx).wav")
// tempo 105
// EMaj

~x = ~b0.play;
~b0.stop;
~x.free;
Buffer.freeAll();


s.options.numBuffers;

440.cpsmidi
63.midicps

l=5;
Env.new([0, 1, 1, 0], [0.02, 0.96, 0.02] * l,curve: [-4, 0, 4]).plot;

