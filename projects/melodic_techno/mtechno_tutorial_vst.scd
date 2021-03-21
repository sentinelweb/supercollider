// an attempt to emulate this series
// https://www.youtube.com/watch?v=hR4W2KyPiTY (bass)
// https://www.youtube.com/watch?v=-rI14gsFQ1k (pads)
// https://www.youtube.com/watch?v=XCTQZRXW6Cg (percussions)
// https://www.youtube.com/watch?v=7xJiHbOm8-E (melodies)

// https://www.youtube.com/watch?v=U2TPAmf1W3Y (kicks)
// https://www.youtube.com/watch?v=HmWB1bXuT6g (breaks)
// https://www.youtube.com/watch?v=FZeT1oc0RvI (claps)

(
s=Server.default;
//s.plotTree;
//s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
~makeBusses = {
	s.newBusAllocators;
	~reverbBus = Bus.audio(s,2);
	~reverbTomBus = Bus.audio(s,2);
	~percBus = Bus.audio(s,2);
	~wobbleBus = Bus.audio(s,2);
	~masterBus = Bus.audio(s,2);
	~emptyInBus = Bus.audio(s,2);

	("MadeBus:"++~masterBus).postln;
	s.sync;
};
~path = PathName(thisProcess.nowExecutingPath).parentPath;
~pathData = ~path++"data/";
~makeNodes = {
	//s.bind({
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp);
		~masterGrp = Group.after(~reverbGrp);
	//});
	"buffers creatd".postln;
	s.sync;
};

~makeBuffers = {
	var vpath;
	vpath = ~path++"vocals/";
	~vocals = Dictionary.new;
	PathName(vpath).entries.do{
		arg file;
		var key,buf;
		key = file.fileName.split($-)[0].asSymbol;
		buf = Buffer.read(s, file.fullPath);
		if (~vocals[key].isNil) {~vocals.add(key -> [])};
		~vocals[key] = ~vocals[key].add(buf);
	};
	"buffers creatd".postln;
	s.sync;
};
ServerTree.add(~makeNodes);
ServerBoot.add(~makeBusses);
ServerTree.add(~makeBuffers);
ServerBoot.add({s.plotTree});

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
	CmdPeriod.removeAll;
	"cleanup".postln;
};

ServerQuit.add(~cleanup);

~makeSynths = {// todo try making this whole thing a function and adding to ServerTree
	/* ----------------------
	Synthetic bass drum
	---------------------- */
	SynthDef(\kick, {
		arg  out = 0, amp = 0.5, dura = 0.25, freq = 50, metal = 1.1, makeup_gain=1;
		var amp_env, freq_env, phase_env, phase, sig, mid_sig, sub_env, sub_sig, hit_env, hit_sig;

		amp_env   = EnvGen.ar(Env.perc(1e-6, dura), doneAction:2) * amp;
		freq_env  = EnvGen.ar(Env.new([1, 0.5, 0.5],[0.5, 1]*dura), doneAction:2) * freq;
		phase_env = EnvGen.ar(Env.perc(1e-6, 0.125));
		phase = SinOsc.ar(20, 0, pi) * phase_env;
		mid_sig = SinOsc.ar([freq_env, metal*freq_env], phase) * amp_env;

		sub_env = EnvGen.ar(Env.new([0, 1, 1, 0]*amp, [0.4, 0.2] * dura, curve:\sine), doneAction:0);
		sub_sig = SinOsc.ar(freq) * sub_env;

		hit_env = EnvGen.ar(Env.new([0, 1, 0.5, 0]*2*amp,[1e-4, 0.01, 0.03]*dura, curve:-1), doneAction:0);
		hit_sig = (SinOsc.ar(freq*2)+BPF.ar(WhiteNoise.ar(10), freq: freq, rq: 0.5)) * hit_env;

		sig = sub_sig + mid_sig + hit_sig;

		sig = Compander.ar(sig, sig, thresh:0.8, slopeBelow:2, slopeAbove:0.6, clampTime:0.035, relaxTime:0.3) * makeup_gain;

		Out.ar(out, sig);
	}).add;

	/* ----------------------
	Synthetic triangle
	---------------------- */
	SynthDef(\tri, {
		arg amp = 0.5, dura = 0.25, freq = 50, metal = 1.1, out = 0 ;
		var amp_env, phase_env, phase, sig;

		amp_env   = EnvGen.ar(Env.perc(1e-6,dura), doneAction:2);
		phase_env = EnvGen.ar(Env.perc(1e-6,0.125));

		phase = SinOsc.ar(20,0,pi) * phase_env;
		sig = SinOsc.ar([freq, metal*freq], phase) * amp_env * amp;

		Out.ar(out, sig);
	}).add;

	/* ----------------------
	Synthetic snare
	---------------------- */
	SynthDef(\snare, {
		arg amp = 0.5, freq = 3000, dura = 0.25, out = 0;
		var amp_env, sig;

		amp_env = EnvGen.ar(Env.perc(1e-6, dura), doneAction:2);
		sig = LPF.ar( {WhiteNoise.ar(WhiteNoise.ar)}.dup * amp_env, freq ) * amp;

		Out.ar(out, sig);
	}).add;


	/* ----------------------
	Synthetic hi-hat
	---------------------- */
	SynthDef(\hat, {
		arg amp = 0.5, freq = 6000, dura = 0.25, out = 0;

		var amp_env,sig  ;
		amp_env = EnvGen.ar(Env.perc(1e-7, dura), doneAction:2);
		sig = HPF.ar( {WhiteNoise.ar}.dup * amp_env, freq ) * amp / 4;

		Out.ar(out, sig);
	}).add;

	/* ----------------------
	reverb
	---------------------- */
	SynthDef(\reverb, {
		arg in,out, mix = 0.25, room = 0.15, damp = 0.5, amp = 1.0;
		var signal;

		signal = In.ar(in, 2);

		Out.ar(out,
			FreeVerb2.ar( // FreeVerb2 - true stereo UGen
				signal[0], // Left channel
				signal[1], // Right Channel
				mix, room, damp, amp
			)
		); // same params as FreeVerb 1 chn version

	}).add;
	// https://blog.rumblesan.com/post/53271713909/drum-sounds-in-supercollider-part-2

	SynthDef('clap', {
		arg out=0,dura = 1,hit=50,freq=3000,wid=2000, amp=1;
		var claposc, clapnoise, clapoutput, clap_env, hit_osc, hit_env;

		clap_env   = EnvGen.ar(Env.perc(1e-6,dura), doneAction:2);
		clapnoise = {BPF.ar(LPF.ar(WhiteNoise.ar(1),(freq+wid)),(freq-wid))};

		clapoutput = {Splay.arFill(7,
			{arg i;
				EnvGen.ar(
					Env.new(
						[0,0,1,0],
						[0.01 * i,0,0.04]
					)
				) * clapnoise * 0.5
			}
		)};

		hit_env   = EnvGen.ar(Env.perc(1e-6, dura*0.005), doneAction:0);
		hit_osc = BPF.ar(WhiteNoise.ar(1), freq: hit.midicps, rq:0.1, mul:1);

		Out.ar(out,
			Pan2.ar(((clapoutput * clap_env) + (hit_osc * hit_env)) * amp, 0)
		)

	}).add;

	SynthDef(\dummy, { }).add;

	SynthDef(\gain, {arg in, out = 0,amp;
		var sig;
		sig = In.ar(in, 2);
		Out.ar(out, sig * amp);
	}).add;

	SynthDef(\vocals, {
		arg c1=1, c2=(-1),
		buf =0, rate=1, spos=0,
		pan=0, amp=1, out=0;
		var sig, env;
		var rateScale = rate*BufRateScale.ir(buf);
		env = EnvGen.kr(Env([0,1,1,0],[0.05,0.99,0.05]*BufDur.ir(buf)/rateScale,[c1,0,c2]),doneAction:2);
		sig = PlayBuf.ar(2, buf, rateScale, startPos:spos);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\pad, { arg out, sigBufNum, shapeBufNum, f=48, amp=1, rq=2, lfo_freq=5, lfo_wid=20;
		var sig, freqs;
		freqs = (f+[0,5,7]).midicps;
		freqs.postln;
		sig = BPF.ar(
			Shaper.ar(shapeBufNum, Osc.ar(sigBufNum, freqs, mul:1/freqs.size)),
			freq: freqs[0] + SinOsc.kr(lfo_freq, mul:lfo_wid),
			rq:rq
		);
		Out.ar(out, sig*amp!2);
	}).add;

	// driving base
	SynthDef(\drivingBase, { arg in, out, sideChain, amp=1;
		var sig, sideChainSig;
		sig = In.ar(in, 2);
		sig = VSTPlugin.ar(sig, 2, id: \serum);
		sideChainSig = InFeedback.ar(sideChain, 2);// take input from last block as reverbGroup is out of order
		//sideChainSig.scope("SideChain input");
		sig = VSTPlugin.ar(sig, 2, id: \eq, auxInput: sideChainSig);//, auxInput: sideChainSig
		Out.ar(out, sig*amp);
	}).add;

	// lead
	SynthDef(\lead, { arg in, out, amp=1;
		var sig;
		sig = In.ar(in, 2);
		sig = VSTPlugin.ar(sig, 2, id: \serum);
		sig = VSTPlugin.ar(sig, 2, id: \eq);
		Out.ar(out, sig*amp);
	}).add;

	// leadMono
	SynthDef(\leadMono, { arg in, out, amp=1;
		var sig;
		sig = In.ar(in, 2);
		sig = VSTPlugin.ar(sig, 2, id: \serum);
		sig = VSTPlugin.ar(sig, 2, id: \eq);
		Out.ar(out, sig*amp);
	}).add;

	//https://sccode.org/1-5cS
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

	//https://sccode.org/1-5cS
	SynthDef(\wobbleDelay, { | out, in, wet = 0.4 |
		var input = In.ar(in,2);
		var rev = Greyhole.ar(input * wet,
			delayTime:0.5, feedback:0.5, diff:0.4,
			damp:0.5, modDepth:0.8, modFreq:0.3);
		Out.ar(out, input + rev);
	}).add;

	s.sync;

	"synths created".postln;
};
~makeConfig = {
	VSTPlugin.search(verbose:true);
	s.sync;
	~config = ();

	~openEditors = {arg key;
		~config[key][\serum].editor;
		~config[key][\eq].editor;
	};

	~save = {arg key;
		~config[key][\serum].writeProgram(~pathData++key++"_serum.fxp");
		~config[key][\eq].writeProgram(~pathData++key++"_eq.fxp");
	};

	~load = {arg key;
		~config[key][\serum].readProgram(~pathData++key++"_serum.fxp");
		~config[key][\eq].readProgram(~pathData++key++"_eq.fxp");
	};
	// todo some execution order issue here - same value for every key
	// ~loadParams = {arg key;
	// 	~config[key][\serumParams].keys.do{arg pkey;
	// 		var ctr=1;
	// 		Routine({~config[key][\serum].get(pkey,{arg f;ctr.wait;ctr=ctr+1; ~config[key][\serumParams][pkey] = f;[key, pkey,f].postln}); }).play;
	// 	}
	// };

	//pad
	~config[\pad] = ();
	~config[\pad][\bufSignal] = Buffer.alloc(s, 2048);
	~config[\pad][\bufShaper] = Buffer.alloc(s, 2048);
	~config[\pad][\bufSignal].loadCollection(Env([0,1,-1,0], [1,0,1]).asSignal(1024).asWavetableNoWrap);
	~config[\pad][\bufShaper].loadCollection(Env([-0.2,0,0.2], [1,1], [25,-25]).asSignal(1025).asWavetableNoWrap);

	~percGain = Synth.new(\gain, [\in, ~percBus, \out, ~masterBus, \amp, 1], ~reverbGrp);// order matters (before reverbs)
	~reverbSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbBus, \out, ~percBus ], ~reverbGrp );
	~reverbTomSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbTomBus, \out, ~percBus ], ~reverbGrp );

	~config[\drivingBase] = ();
	~config[\drivingBase][\synth] = Synth(\drivingBase, [\out, ~masterBus, \sideChain, ~reverbBus, \in, ~emptyInBus], ~mainGrp);
	~config[\drivingBase][\serum] = VSTPluginController(~config[\drivingBase][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\drivingBase][\serumParams]= (Dist_Drv:0.103, Dist_BW:0.352, Dist_Freq:0.462);
	~config[\drivingBase][\eq] = VSTPluginController(~config[\drivingBase][\synth], \eq).open("/Library/Audio/Plug-Ins/VST3/TDR Nova.vst3", verbose: true,  editor:true);

	~config[\lead] = ();
	~config[\lead][\synth] = Synth(\lead, [\out, ~masterBus, \in, ~emptyInBus], ~mainGrp);
	~config[\lead][\serum] = VSTPluginController(~config[\lead][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\lead][\eq] = VSTPluginController(~config[\lead][\synth], \eq).open("/Library/Audio/Plug-Ins/VST3/TDR Nova.vst3", verbose: true,  editor:true);

	~config[\leadMono] = ();
	~config[\leadMono][\synth] = Synth(\leadMono, [\out, ~masterBus, \in, ~emptyInBus ], ~mainGrp);
	~config[\leadMono][\serum] = VSTPluginController(~config[\leadMono][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\leadMono][\eq] = VSTPluginController(~config[\leadMono][\synth], \eq).open("/Library/Audio/Plug-Ins/VST3/TDR Nova.vst3", verbose: true,  editor:true);

	~config[\wobble]= ();
	~config[\wobble][\delay] = Synth(\wobbleDelay, [\out, ~masterBus, \in, ~wobbleBus]);
	s.sync;

	~apc = AkaiAPC40();

	~load.(\drivingBase);
	~load.(\lead);
	~load.(\leadMono);
	s.sync;
	// ~loadParams.(\drivingBase);


	~reverbSynth.set(\mix, 0.5, \room, 0.5, \damp, 1);
	~reverbTomSynth.set(\mix, 0.3, \room, 0.3, \damp, 1);

	~masterGain = Synth.new(\gain, [\in, ~masterBus, \amp, 0.7], ~masterGrp);
	s.sync;
	"config created".postln;
};// makePiece
ServerTree.add(~makeSynths);
ServerTree.add(~makeConfig);
)

~openEditors.(\drivingBase);
~save.(\drivingBase);

~openEditors.(\lead);
~save.(\lead);

~openEditors.(\leadMono);
~save.(\leadMono);


FreqScope.new(400, 200, busNum:0, server: s);

~config[\pad][\bufSignal].sine3([0,1,2,3,4,5], [0.25, 0.5, 0.75,], normalise:true, asWavetable:true);
~config[\pad][\bufSignal].loadCollection(Env([0,1,-1,0], [1,0,1]).asSignal(1024).asWavetableNoWrap);
~config[\pad][\bufShaper].loadCollection(Env([-0.2,0,0.2], [1,1], [50,-50]).asSignal(1025).asWavetableNoWrap);

~cmp[\leadMono] = (off: 24, amp: 0.3);
~cmp[\pad] = (off: 12, amp: 0.3);
// sequence
(
~freeAll= {Pdef(\compose).stop;Pdef(\kick).stop;Pdef(\tom).stop;Pdef(\clap).stop;Pdef(\hat).stop;Pdef(\tri).stop;Pdef(\drivingBase).stop;Pdef(\lead).stop;Pdef(\leadMono).stop;Pdef(\vocals).stop;Pdef(\wobble).stop;}
CmdPeriod.add(~freeAll);
~tempoClock.tempo = 123/60;
~cmp = (
	perc:(
		kick:(amp:1.2),
		tom:(amp:0.5),
		clap:(idx: Seqr[0, 3, 0, 2, 1, 3, 1, 0], note: 122, amp:1.3),
		tri:(amp:0.02),
	),
	// todo tune these changes better - some changes are better than others
	bass:(seq: Seqr[29, 31, 32, 35, 33, 29, 27, 28, 31, 29, 27, 31, 27, 29, 28, 31], amp: 0.9),
	lead:(off: 24, amp: 0.0),
	leadMono:(off: 24, amp: 0.0),
	pad:(off: 12, amp: 0.0),
	vocals:(samp: \being, amp: 0),
	wobble:(amp: 0.1)
);
~cmp[\bass][\seq].next;
~cmp[\perc][\clap][\idx].next;
Pdef(\compose, Pmono(
	\dummy,
	\baseNote, Pfunc({~cmp[\bass][\seq].next}),
	\clap, Pfunc({~cmp[\perc][\clap][\idx].next}),
	\clapNote, Pfunc({~cmp[\perc][\clap][\note]=exprand(100,120).asInteger}),
	\vocal, Pfunc({~cmp[\vocals][\samp]=~vocals.keys.choose}),
	\dur, 16
)).quant_(~tempoClock.beatsPerBar);

Pdef(\kick, Pbind(\instrument, \kick, \amp, Pfunc({~cmp[\perc][\kick][\amp]}), \dur, 1, \midinote, 29, \dura, 0.6, \metal, 1.6, \makeup_gain, 1.3,\group, ~mainGrp, \out, ~reverbBus)
).quant_(~tempoClock.beatsPerBar);

Pdef(\tom, Pbind(\instrument, \kick, \amp, Pfunc({~cmp[\perc][\tom][\amp]}), \dur, Pseq([Rest(0)+5,1,1, Rest(0)+1]/2, inf), \midinote, Pseq([0, 35, 40, 0], inf), \dura, 0.3, \metal, 2.5,\group, ~mainGrp, \out, ~reverbTomBus)
).quant_(~tempoClock.beatsPerBar);

Pdef(\clap, Pbind(\instrument, \clap, \amp, 1.3,  \hit, 30,\midinote, Pfunc({~cmp[\perc][\clap][\note]}), \wid, 200, \dura,  1,\group, ~mainGrp, \out, ~reverbTomBus,
		\dur, Pswitch([
			Pseq([Rest(0)+14,1,1]/4,4),
			Pseq([Rest(0)+12,1,1,1,1]/4,4),
			Pseq([Rest(0)+12,1,Rest(1),1,1]/4,4),
			Pseq([Rest(0)+12,1,1,Rest(1),1]/4,4)
		],
		Pfunc({~cmp[\perc][\clap][\idx].v}),
		inf
	))
).quant_(~tempoClock.beatsPerBar);

Pdef(\hat, Pbind(\instrument, \hat, \amp, Pseq([0.2, 0.6, 0.9, 1.0], inf), \dur, 1/4, \midinote, 92, \dura,  0.12, \out, ~percBus, \group, ~mainGrp)
).quant_(~tempoClock.beatsPerBar);

Pdef(\tri, Pbind(\instrument, \tri,  \dur, 16,\amp, 0.02, \midinote, Pfunc({~cmp[\bass][\seq].v+72}),\dura, 2, \metal, 1.003,\out, ~percBus, \group, ~mainGrp)
).quant_(~tempoClock.beatsPerBar);

~perc = {|play|
	if (play) {
		Pdef(\kick).play;
		Pdef(\tom).play;
		Pdef(\clap).play;
		Pdef(\hat).play;
		Pdef(\tri).play;
	}{
		Pdef(\kick).stop;
		Pdef(\tom).stop;
		Pdef(\clap).stop;
		Pdef(\hat).stop;
		Pdef(\tri).stop;
	}
};
~percIsPlaying = {
	Pdef(\kick).isPlaying || Pdef(\tom).isPlaying || Pdef(\clap).isPlaying || Pdef(\hat).isPlaying || Pdef(\tri).isPlaying;
};
//~perc =  Ppar([Pdef(\kick), Pdef(\tom), Pdef(\clap), Pdef(\hat), Pdef(\tri)]);//.quant_(~tempoClock.beatsPerBar);
/*Pdef(\perc, Ppar([Pdef(\kick), Pdef(\tom), Pdef(\clap), Pdef(\hat), Pdef(\tri)])
).quant_(~tempoClock.beatsPerBar);*/

// glock
//Pbind(\instrument, \kick,  \dur, 4,\amp, 0.15, \midinote, Pxrand((Scale.minor.degrees+60),inf),\dura, 4, \metal, 1.05),
// snare
//Pbind(\instrument, \snare,  \dur, Pseq([Rest(2),1,1], inf), \amp, 1,\midinote, 120, \dura,  0.2),

// base low range (30-150) (23-50)
//https://www.youtube.com/watch?v=hR4W2KyPiTY&t=1155s
// eefects to add, delay, move distortion curve, hyper + detune
Pdef(\drivingBase, Ppar([
	// driving base
	Pbind(\type, \vst_midi,
		\vst, ~config[\drivingBase][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\chan, 0,
		\dur, 1/4,
		\midinote, Pseq([0, 0, 0, 0, 7, 12, 12, 12], inf) + Pfunc({~cmp[\bass][\seq].v}),
	),
	Pbind(\type, \set, \id,~config[\drivingBase][\synth], \amp, Pfunc({~cmp[\bass][\amp]}), \dur, 1/4)
])
).quant_(~tempoClock.beatsPerBar);

Pdef(\lead, Ppar([
	Pbind(\type, \vst_midi,
		\vst, ~config[\lead][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\dur, 1/4,
		\chan, 0,
		\midinote, Pseq([1, 7, 8], inf) + Pfunc({~cmp[\bass][\seq].offset(~cmp[\lead][\off])})
	),
	Pbind(\type, \set, \id, ~config[\lead][\synth], \amp, Pfunc({~cmp[\lead][\amp]}))
])
).quant_(~tempoClock.beatsPerBar);

Pdef(\leadMono,  Ppar([
	Pbind(\type, \vst_midi,
		\vst, ~config[\leadMono][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\dur, Pseq([1, 1, 2] * 4, inf),
		\chan, 0,
		\midinote, Pseq([8, 5, 0], inf) + Pfunc({~cmp[\bass][\seq].offset( ~cmp[\leadMono][\off])})
	),
	Pbind(\type, \set, \id, ~config[\leadMono][\synth], \amp, Pfunc({~cmp[\leadMono][\amp]}))
])).quant_(~tempoClock.beatsPerBar);

Pdef(\pad, Pmono( \pad,
	\dur, 1,
	\amp, Pfunc({~cmp[\pad][\amp]}),
	\f, Pfunc({~cmp[\bass][\seq].offset(~cmp[\pad][\off])}),
	\out, ~masterBus,
	\sigBufNum, ~config[\pad][\bufSignal].bufnum,
	\shapeBufNum,	~config[\pad][\bufShaper].bufnum,
	\group, ~mainGrp
)).quant_(~tempoClock.beatsPerBar);

Pdef(\vocals, Pbind(\instrument, \vocals,
	\buf, Pfunc({~vocals[~cmp[\vocals][\samp]].choose.bufnum}),
	\amp, Pfunc({~cmp[\vocals][\amp]}),
	\rate, Pfunc({0.7*(~cmp[\bass][\seq].v-27).midiratio}),
	\dur, 16,
	\out, ~masterBus,
	\group, ~mainGrp
)).quant_(~tempoClock.beatsPerBar);

Pdef(\wobble,Pbind(
	\instrument, \wobble,
	\legato, 0.98,
	\out, ~wobbleBus,
	\dur, Pseq([8, Rest(8)],inf),
	\amp, Pfunc({~cmp[\wobble][\amp]}),
	\wflo, 1,
	\wfhi, 2,
	\wfmax, 1000,
	\iphase, 0.25,
	\degree, Pseq([-2,0,2,2], inf),
	\octave, 2,
)).quant_(~tempoClock.beatsPerBar);

PdefAllGui();

// perc
~apc.addNoteIn(\track1,{ ~perc.value(~percIsPlaying.value.not)});
~apc.addNoteOut(\track1, { if (~percIsPlaying.value) {\red}{\off}});
~apc.addNoteIn(\grid14,~apc.togPdef(\hat));
~apc.addNoteOut(\grid14, { if (Pdef(\hat).isPlaying) {\yellow}{\off}});
~apc.addNoteIn(\grid15,~apc.togPdef(\tri));
~apc.addNoteOut(\grid15, { if (Pdef(\tri).isPlaying) {\white}{\off}});
~apc.addNoteIn(\grid13,~apc.togPdef(\clap));
~apc.addNoteOut(\grid13, { if (Pdef(\clap).isPlaying) {\purple}{\off}});
~apc.addNoteIn(\grid12,~apc.togPdef(\tom));
~apc.addNoteOut(\grid12, { if (Pdef(\tom).isPlaying) {\orange}{\off}});
~apc.addNoteIn(\grid11,~apc.togPdef(\kick));
~apc.addNoteOut(\grid11, { if (Pdef(\kick).isPlaying) {\red}{\off}});
~apc.addCtlIn(\s1,{~percGain.set(\amp, ~val.linexp(0,127,0.01,1.5))});
~apc.addCtlIn(\k1,{~cmp[\perc][\kick][\amp] = ~val.linlin(0,127,0.01,2)});
~apc.addCtlOut(\k1,{~cmp[\perc][\kick][\amp].linlin(0.01,2,0,127).asInteger});

~apc.addNoteIn(\track2,~apc.togPdef(\drivingBase));
~apc.addNoteOut(\track2, {if (Pdef(\drivingBase).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s2,{~cmp[\bass][\amp] = ~val.linexp(0,127,0.01,1.2)});
~apc.addCtlIn(\k2,{~config[\drivingBase][\serum].set(\Dist_Freq, ~val.linlin(0,127,0.3,0.8))});

~apc.addNoteIn(\track3,~apc.togPdef(\lead));
~apc.addNoteOut(\track3, { if (Pdef(\lead).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s3,{~cmp[\lead][\amp] = ~val.linexp(0,127,0.01,1.2)});
~apc.addNoteIn(\track4,~apc.togPdef(\leadMono));
~apc.addNoteOut(\track4, {if (Pdef(\leadMono).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s4,{~cmp[\leadMono][\amp] = ~val.linexp(0,127,0.01,1.2)});
~apc.addNoteIn(\track5,~apc.togPdef(\pad));
~apc.addNoteOut(\track5, {if (Pdef(\pad).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s5,{~cmp[\pad][\amp] = ~val.linexp(0, 127, 0.01, 1.2)});
~apc.addNoteIn(\track6,~apc.togPdef(\vocals));
~apc.addNoteOut(\track6, {if (Pdef(\vocals).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s6,{~cmp[\vocals][\amp] = ~val.linexp(0, 127, 0.01, 2)});
~apc.addNoteIn(\track7,~apc.togPdef(\wobble));
~apc.addNoteOut(\track7, {if (Pdef(\wobble).isPlaying) {\on}{\off}});
~apc.addCtlIn(\s7,{~cmp[\wobble][\amp] = ~val.linexp(0, 127, 0.01, 0.8)});
~apc.addNoteIn(\sceneMstr,~apc.togPdef(\compose));
~apc.addNoteOut(\sceneMstr, { if (Pdef(\compose).isPlaying) {\on}{\off}});
~apc.addCtlIn(\master,{~masterGain.set(\amp, ~val.linexp(0, 127, 0.01, 1.2)) });

)
//////////////////////////////////////////////////////////////////////////
//////////////////////////////// test area ///////////////////////////////
//////////////////////////////////////////////////////////////////////////
Platform.userExtensionDir

~apc.update
~makeBuffers.value
~vocals.keys
~config[\drivingBase][\serum].set(\Dist_Drv, 0.5);
~config[\drivingBase][\serum].set(\Dist_BW, 0.7);
~config[\drivingBase][\serum].set(\Dist_Freq, 0.56);
~config[\drivingBase][\serum].get(\Dist_Drv,{arg f; f.postln;});
~config[\drivingBase][\serum].get(\Dist_BW,{arg f; f.postln;});
~config[\drivingBase][\serum].get(\Dist_Freq,{arg f; f.postln;});
~cmp[\perc][\kick][\amp].linlin(0.01,2,0,127).asInteger
~vocal = Synth(\vocals,[\buf, ~vocals[\being][0].bufnum, \amp, 1]);
~arp = Synth(\arp,[\midinote, 65, \amp, 0.5, \filterRatio:4, \spread:5, \dura, 0.25]);
~kick = Synth.new(\kick,[\freq, 20, \dura, 0.5, \metal, 2]);
~kick = Synth.new(\kick,[\freq, 28.midicps, \dura, 0.5, \metal, 1.3, \amp, 1]);
~glock = Synth.new(\kick,[\amp,0.8, \freq,70.midicps, \metal:1])
~snare = Synth.new(\snare,[\amp,0.8, \freq, 1000 /* 200-20000*/, \dur, 0.2 /* 0.05 - 1 */])
~hatTest = Synth.new(\hat,[\amp,0.8, \freq,100.midicps /* 2000 heavy - 20000 lightest*/, \dur, 0.8 /* 0.05 closed - 1 open */])
~triangle = Synth.new(\kick,[\freq, 110.midicps, \dura, 1, \metal, 1]);
~clap = Synth(\clap, [\hit, 40, \freq,4000, \wid, 2000, \dura, 2]);
(
~config = ();
~config[\pad] = ();
~config[\pad][\bufSignal] = Buffer.alloc(s, 2048);
~config[\pad][\bufShaper] = Buffer.alloc(s, 2048);
~config[\pad][\bufSignal].loadCollection(Env([0,1,-1,0], [1,0,1]).asSignal(1024).asWavetableNoWrap);
~config[\pad][\bufShaper].loadCollection(Env([-0.2,0,0.2], [1,1], [25,-25]).asSignal(1025).asWavetableNoWrap);

SynthDef(\pad, { arg bus,f=48, amp=1, rq=2, lfo_freq=5, lfo_wid=20;
	var sig, freqs;
	freqs = (f+[0,5,7]).midicps;
	freqs.postln;
	sig = BPF.ar(
		Shaper.ar(~config[\pad][\bufShaper], Osc.ar(~config[\pad][\bufSignal], freqs, mul:1/freqs.size)),
		freq: freqs[0] + SinOsc.kr(lfo_freq, mul:lfo_wid),
		rq:rq
	);
	Out.ar(bus, sig*amp!2);
}).add;
    //~config[\pad][\synth] = Synth(\pad, [\bus, 0, \amp, 0]);
)
p = Pmono(\pad, \dur, 4, \f, 60).play;
p.stop;
~bufSignal = Buffer.alloc(s, 2048);
~bufSignal.sine3([1,3,5], [0.5, 0.25, 0.75], normalise:true, asWavetable:true);
~sigSaw = Env([0,1,-1,0], [1,0,1]).asSignal(1024).asWavetableNoWrap;
~bufSignal.loadCollection(~sigSaw);
~bufShaper = Buffer.alloc(s, 2048);

Env.perc(1e-6, dura * 0.5).plot
Env.perc(1e-6,1).plot

Env.sine(1, 1).test.plot;

Env.adsr(1e-3, 0.02, 0.5, 0.1, curve:0).plot

Env.new([0,1,1,0],[0.4,0.6], curve:\sine).plot;
Env.new([0, 1, 1, 0]*2, [0.4, 0.2] * 1.5, curve:\sine).plot;


~sq =Seqr[40,45,50];
~sq.next;
~sq.v
~sq.pos
MIDIClient.init;
~indexOfAkai = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("APC40 mkII")});
~midiOut = MIDIOut.new(~indexOfAkai, MIDIClient.destinations.at(~indexOfAkai).uid);
~midiOut.latency = 0.0;
~midiOut.control(0, 15, 127);
~midiOut.noteOn(0, 15, 65);
~midiOut.noteOn(0, 15, 77);
~index
r = Routine({{(0..127).do{arg i;~midiOut.noteOn(0, 15, i);i.postln;5.wait}}.loop})
r.play
r.stop
~midiOut.noteOn(0, 62, 0);
//\red:5,\orange:9,\yellow:13,\yel_grn:75,\green:17,\teal:65,\cyan:37,\blue:45,\move:53,\pink:57,\purple:49, \white:119
~apc = AkaiAPC40();
~apc.addCtlIn(\k1,{["k1",~val].postln});
~apc.addNoteIn(\grid11,{if (Pdef(\compose).isPlaying){Pdef(\compose).stop}{Pdef(\compose).play}});
~apc.addNoteOut(\grid11,{if (Pdef(\compose).isPlaying) {127}{0}});
~apc.addNoteOut(\grid22,{\off});
~apc.update
~apc.dump
//~apc.t({~val.postln});
{|v|["d",v].postln}.value(4)

MIDIClient.sources.at(0).uid

~vpath = PathName(thisProcess.nowExecutingPath).parentPath++"vocals/";
	~vocals = Dictionary.new;
	PathName(~vpath).entries.do{
		arg file;
		var key = file.fileName.split($-)[0].asSymbol;
		var buf = Buffer.read(s, file.fullPath);
		if (~vocals[key].isNil) {~vocals.add(key -> [])};
		~vocals[key] = ~vocals[key].add(buf);
	};
