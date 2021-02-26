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
~reverbBus = Bus.audio(s,2);
~reverbTomBus = Bus.audio(s,2);
~path = PathName(thisProcess.nowExecutingPath).parentPath++"data/";
~makeNodes = {
	s.bind({
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp);
	});
};
~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};
ServerTree.add(~makeNodes);
ServerQuit.add(~cleanup);
VSTPlugin.search(verbose:true);

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

// SynthDef(\drivingbase, {
// 	arg in,out, freq = 0.25, filterRatio=1.1, amp = 1.0, dura=1, clip=0.8, cbeat=1;
// 	var signal, env;
// 	env   = EnvGen.ar(Env.new([0,amp,0],[dura/2,dura], curve:\sine),doneAction:2);
// 	signal = LPF.ar(LFSaw.ar(freq: freq, iphase: 0.0, mul: 1, add: 0.0), freq*filterRatio);
// 	signal = Clip.ar(signal,0.1,clip)!2;
// 	//signal = COsc.ar(signal, freq, cbeat, 0.5);
// 	Out.ar(out,	signal*env);
// }).add;


SynthDef(\pad, {
	arg in,out, midinote = 30, spread=3, filterRatio=1.1, amp = 1.0, dura=1, mainAmp=0.8, sideAmp=0.1, thresh=0.4;
	var sig, env;
	env  = EnvGen.ar(Env.new([0,amp,amp,0], [0.05,0.95]*dura, curve:\sine), doneAction:2);
	sig = RLPF.ar(
		(
			LFSaw.ar(freq: (midinote-spread).midicps,  mul: sideAmp) +
			LFSaw.ar(freq: midinote.midicps, mul: mainAmp ) +
			LFSaw.ar(freq:  (midinote+spread).midicps,  mul: sideAmp)
		), midinote.midicps*filterRatio, 0.1);
	sig = Compander.ar(sig, ~reverbBus, thresh:thresh, slopeBelow:10, slopeAbove:1, clampTime:0.01, relaxTime:0.5);// not sure if this is working
	sig = LPF.ar(HPF.ar(sig, (midinote-12).midicps), (midinote+12).midicps);
	Out.ar(out,	(sig)*env);
}).add;

SynthDef(\arp, {
	arg in,out, midinote = 30, spread=3, filterRatio=1.1, amp = 1.0, dura=1, mainAmp=0.8, thresh=0.4;
	var sig, env;
	env   = EnvGen.ar(Env.new([0,amp,amp,0], [0.05,0.95]*dura, curve:\sine), doneAction:2);
	sig = SinOsc.ar(freq: [(midinote-spread).midicps,midinote.midicps,(midinote+spread).midicps],  mul: mainAmp);
    sig = LPF.ar(HPF.ar(sig, 200), 2000);
	Out.ar(out,	(sig)*env);
}).add;
~config = ();

~openEditors = {arg key;
~config[key][\serum].editor;
~config[key][\eq].editor;
};

~save = {arg key;
	~config[key][\serum].writeProgram(~path++key++"_serum.fxp");
	~config[key][\eq].readProgram(~path++key++"_eq.fxp");
};

SynthDef(\serumeq, { arg bus;
    var sig;
    sig = VSTPlugin.ar(sig, 2, id: \serum);
    sig = VSTPlugin.ar(sig, 2, id: \eq);
    Out.ar(bus, sig);
}).add;


~config[\drivingBase] = ();
~config[\drivingBase][\synth] = Synth(\serumeq, [\bus, 0]);
~config[\drivingBase][\serum] = VSTPluginController(~config[\drivingBase][\synth],\serum).open("Serum", verbose: true,  editor:true);
~config[\drivingBase][\eq] = VSTPluginController(~config[\drivingBase][\synth], \eq).open("TDR Nova", verbose: true,  editor:true);
~config[\drivingBase][\serum].readProgram(~path++"drivingBase.fxp");



~reverbSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbBus, \out, ~out ], ~reverbGrp );
~reverbTomSynth = Synth.new( \reverb, [ \amp, 1, \mix, 0.75, \room, 0.8, \damp, 0.5, \amp, 1.0, \in, ~reverbTomBus, \out, ~out ], ~reverbGrp );

)

~techno.play;
~techno.stop;

~openEditors.(\drivingBase);

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
		\dur, 1/4, \amp, 0.4,
		\midinote, Pseq([~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote, ~baseBaseNote+2], inf),
	),
]);

// pads mid range (100-250) (44-60 midi)
// https://www.youtube.com/watch?v=-rI14gsFQ1k
~padBaseNote = ~baseBaseNote+24;//53 - f3
~padAmp = 0.04;
~padSpread = 3;
~padSeq = Ppar([
	Pbind(\instrument, \pad,  \amp, ~padAmp, \dur, 4, \midinote, ~padBaseNote, \dura, Pkey(\dur), \filterRatio, 8, \spread, ~padSpread, \sideAmp, 0.5, \mainAmp, 0.5, \thresh, 0.5),
	Pbind(\instrument, \pad,  \amp, ~padAmp, \dur, 4, \midinote, ~padBaseNote+3, \dura, Pkey(\dur), \filterRatio, 8, \spread, ~padSpread, \sideAmp, 0.5, \mainAmp, 0.5, \thresh, 0.5),
	Pbind(\instrument, \pad,  \amp, ~padAmp, \dur, 4, \midinote, ~padBaseNote+7, \dura, Pkey(\dur), \filterRatio, 8, \spread, ~padSpread, \sideAmp, 0.5, \mainAmp, 0.5, \thresh, 0.5),
]);

// https://www.youtube.com/watch?v=7xJiHbOm8-E
~arpBaseNote = ~baseBaseNote+36; // 65- f4
~melodySeq =  Ppar([// \midinote, 65, \amp, 0.5, \filterRatio:4, \spread:5, \dura,0.25
	Pbind(\instrument, \arp,  \amp, 0.6, \dur, 1/4, \midinote, Pseq([1,7,8] + ~arpBaseNote, inf), \dura, 1/16, \filterRatio, 8, \spread, 5, \mainAmp, 0.3),
]);

~techno  = Pdef(\perc, Ppar([ ~percussionSeq, ~baseSeq, ~padSeq, ~melodySeq])).quant = [~tempoClock.beatsPerBar];
)


s.plotTree
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