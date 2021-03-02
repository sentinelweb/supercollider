// an attempt to emulate this series
// https://www.youtube.com/watch?v=hR4W2KyPiTY (bass)
// https://www.youtube.com/watch?v=-rI14gsFQ1k (pads)
// https://www.youtube.com/watch?v=XCTQZRXW6Cg (percussions)
// https://www.youtube.com/watch?v=7xJiHbOm8-E (melodies)

// https://www.youtube.com/watch?v=U2TPAmf1W3Y (kicks)
// https://www.youtube.com/watch?v=HmWB1bXuT6g (breaks)
// https://www.youtube.com/watch?v=FZeT1oc0RvI (claps)

(
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
~tempoClock = TempoClock.default;
~tempoClock.tempo = 125/60;
~makeBusses = {
	s.newBusAllocators;
	~reverbBus = Bus.audio(s,2);
	~reverbTomBus = Bus.audio(s,2);
	("MadeBus:"++~reverbBus).postln;
};
~path = PathName(thisProcess.nowExecutingPath).parentPath++"data/";
~makeNodes = {
	s.bind({
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp);
	});
};

ServerTree.add(~makeNodes);
ServerTree.add(~makeBusses);
~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
	"cleanup".postln;
};

ServerQuit.add(~cleanup);
)
(
s.waitForBoot({
	/* ----------------------
	Synthetic bass drum
	---------------------- */
	SynthDef(\kick, {
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
		arg dura = 1,hit=50,freq=3000,wid=2000;
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

		hit_env   = EnvGen.ar(Env.perc(1e-6,dura*0.005), doneAction:0);
		hit_osc = BPF.ar(WhiteNoise.ar(1), freq: hit.midicps, rq:0.1, mul:1);

		Out.ar(0,
			Pan2.ar((clapoutput * clap_env)+ (hit_osc* hit_env), 0)
		)

	}).add;

	SynthDef(\serumeq, { arg bus, sideChain, amp=1;
		var sig, sideChainSig;
		sig = In.ar(bus, 2);
		sig = VSTPlugin.ar(sig, 2, id: \serum);
		sideChainSig = InFeedback.ar(sideChain, 2);// take input from last block as reverbGroup is out of order
		sideChainSig.scope("SideChain input");
		sig = VSTPlugin.ar(sig, 2, id: \eq, auxInput: sideChainSig);//, auxInput: sideChainSig
		Out.ar(bus, sig*amp);
	}).add;

	s.sync;
	VSTPlugin.search(verbose:true);

	s.sync;
	~config = ();

	~openEditors = {arg key;
		~config[key][\serum].editor;
		~config[key][\eq].editor;
	};

	~save = {arg key;
		~config[key][\serum].writeProgram(~path++key++"_serum.fxp");
		~config[key][\eq].writeProgram(~path++key++"_eq.fxp");
	};

	~load = {arg key;
		~config[key][\serum].readProgram(~path++key++"_serum.fxp");
		~config[key][\eq].readProgram(~path++key++"_eq.fxp");
	};

	~reverbSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbBus, \out, ~out ], ~reverbGrp );
	~reverbTomSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbTomBus, \out, ~out ], ~reverbGrp );

	~config[\drivingBase] = ();
	~config[\drivingBase][\synth] = Synth(\serumeq, [\bus, 0, \sideChain, ~reverbBus]);
	~config[\drivingBase][\serum] = VSTPluginController(~config[\drivingBase][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\drivingBase][\eq] = VSTPluginController(~config[\drivingBase][\synth], \eq).open("/Library/Audio/Plug-Ins/VST3/TDR Nova.vst3", verbose: true,  editor:true);

	/*~config[\pad] = ();
	~config[\pad][\synth] = Synth(\serumeq, [\bus, 0]);
	~config[\pad][\serum] = VSTPluginController(~config[\pad][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\pad][\eq] = VSTPluginController(~config[\pad][\synth], \eq).open("TDR Nova", verbose: true,  editor:true);

	~config[\arp] = ();
	~config[\arp][\synth] = Synth(\serumeq, [\bus, 0]);
	~config[\arp][\serum] = VSTPluginController(~config[\arp][\synth],\serum).open("Serum", verbose: true,  editor:true);
	~config[\arp][\eq] = VSTPluginController(~config[\arp][\synth], \eq).open("TDR Nova", verbose: true,  editor:true);*/


	s.sync;

	~load.(\drivingBase);
	/*~load.(\pad);
	~load.(\arp);*/
});
)
s.plotTree;
~techno.play;
~techno.stop;
~reverbBus.scope;
~openEditors.(\drivingBase);
~save.(\drivingBase);
~load.(\drivingBase);

/*~openEditors.(\pad);
~save.(\pad);
~load.(\pad);

~openEditors.(\arp);
~save.(\arp);
~load.(\arp);*/
// sequence
(
~tempoClock.tempo = 125/60;
~reverbSynth.set(\mix, 0.5, \room, 1, \damp, 1);
~reverbTomSynth.set(\mix, 0.8, \room, 0.3, \damp, 1);
//https://www.youtube.com/watch?v=XCTQZRXW6Cg
~percussionSeq = Ppar([
	// kick
	Pbind(\instrument, \kick,	\amp, 1.0, \dur, 1,\midinote, 10,	\dura, 0.5,	\metal, 3,\group, ~mainGrp, \out, ~reverbBus),
	// tom

	Pbind(\instrument, \kick, \amp, 1, \dur, Pseq([Rest(5),1,1, Rest(1)]/2, inf),\midinote, Pseq([0,35,40,0],inf),	\dura, 0.3,	\metal, 2.5,\group, ~mainGrp, \out, ~reverbTomBus),
	Pbind(\instrument, \clap, \amp, 1,  \dur, Pseq([Rest(14), 1, 1]/4,inf),\hit, 40,\midinote, 116, \wid, 200, \dura,  1,\group, ~mainGrp, \out, ~reverbBus),
	Pbind(\instrument, \hat,  \amp, Pseq([0.2, 0.6, 0.9, 1.0], inf), \dur, 1/4, \midinote, 92, \dura,  0.12),
	/*triangle*/
	// Pbind(\instrument, \kick,  \dur, 8,\amp, 0.15, \midinote, Pseq([100, 103,104,102, 110],inf),\dura, 4),
	/*glock*/
	//Pbind(\instrument, \kick,  \dur, 4,\amp, 0.15, \midinote, Pxrand((Scale.minor.degrees+60),inf),\dura, 4, \metal, 1.05),
	//Pbind(\instrument, \snare,  \dur, Pseq([Rest(2),1,1], inf), \amp, 1,\midinote, 120, \dura,  0.2),
]);

// base low range (30-150) (23-50)
//https://www.youtube.com/watch?v=hR4W2KyPiTY&t=1155s
~baseBaseNote = 29;//29 - f1
~baseSeq = Ppar([
	// driving base
	Pbind(\type, \vst_midi,
		\vst, ~config[\drivingBase][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\chan, 0,
		\dur, 1/4,
		\midinote, Pseq([~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote+2], inf),
	),
	Pbind(\type, \set, \id,~config[\drivingBase][\synth], \amp, 0.8)
]);
/*
// pads mid range (100-250) (44-60 midi)
// https://www.youtube.com/watch?v=-rI14gsFQ1k
~padBaseNote = ~baseBaseNote+24;//53 - f3
~padAmp = 0.04;
~padSpread = 3;
~padSeq = Ppar([
	Pbind(\type, \vst_midi,
		\vst, ~config[\pad][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\dur, 4,
		\chan, 0,
		\midinote, [~padBaseNote, ~padBaseNote+3, ~padBaseNote+7]
	),
	Pbind(\type, \set, \id, ~config[\pad][\synth], \amp, ~padAmp)
]);

// https://www.youtube.com/watch?v=7xJiHbOm8-E
~arpBaseNote = ~baseBaseNote+36; // 65- f4
~melodySeq =  Ppar([// \midinote, 65, \amp, 0.5, \filterRatio:4, \spread:5, \dura,0.25
	/*Pbind(\instrument, \arp,  \amp, 0.6, \dur, 1/4, \midinote, Pseq([1,7,8] + ~arpBaseNote, inf), \dura, 1/16, \filterRatio, 8, \spread, 5, \mainAmp, 0.3),*/
	Pbind(\type, \vst_midi,
		\vst, ~config[\arp][\serum], // the VSTPluginController instance
		\midicmd, \noteOn,
		\dur, 1/4,
		\chan, 0,
		\midinote, Pseq([1,7,8] + ~arpBaseNote, inf)
	),
	Pbind(\type, \set, \id, ~config[\arp][\synth], \amp, 0.4)
]);
*/
~techno  = Pdef(\perc,
	Ppar([ ~percussionSeq, ~baseSeq/*, ~padSeq, ~melodySeq*/])
).quant = [~tempoClock.beatsPerBar];
)



~arp = Synth(\arp,[\midinote, 65, \amp, 0.5, \filterRatio:4, \spread:5, \dura,0.25]);
~kick = Synth.new(\kick,[\freq,20,\dura,0.5, \metal,2]);
~kick = Synth.new(\kick,[\freq,40.midicps,\dura,0.5, \metal,2]);
~glock = Synth.new(\kick,[\amp,0.8,\freq,70.midicps, \metal:1])
~snare = Synth.new(\snare,[\amp,0.8,\freq, 1000 /* 200-20000*/, \dur, 0.2 /* 0.05 - 1 */])
~hatTest = Synth.new(\hat,[\amp,0.8,\freq,100.midicps /* 2000 heavy - 20000 lightest*/, \dur, 0.8 /* 0.05 closed - 1 open */])
~triangle = Synth.new(\kick,[\freq,110.midicps,\dura,1, \metal,1]);
~clap = Synth(\clap, [\hit,40, \freq,4000,\wid,2000, \dura,2]);
~base = Synth(\base,[\freq, 25.midicps, \amp,5, \clip,0.25]);


Env.perc(1e-6,1).plot

Env.new([0,1,1,0],[0.05,0.95], curve:\sine).plot;