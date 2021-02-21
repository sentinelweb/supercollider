(
///// REFS ////////////////////////////////////////////////////////////////////////////
// from https://www.youtube.com/watch?v=lGs7JOOVjag&t=1664s
// https://www.youtube.com/watch?v=P85X1Ut3Hfc
///////////////////////////////////////////////////////////////////////////////////////
///// TODOS ///////////////////////////////////////////////////////////////////////////
// - make more sequences for chorus (make an event to change it)
// - more song phases
// + put reverb on precussion
// + MIDI control
// - when intro tempo isnt 120 there are artifacts (some delay somewhere?)
// - look at levels and EQ to pop more
// - add more percussion rhythms and tweak
// - find wood wind sound (drone)
///////////////////////////////////////////////////////////////////////////////////////
//1. server config ////////////////////////////////////////////////////////////////////
s = Server.local;

s.quit;
// s.sync;

s.options.outDevice_(
	"Built-in Output"
	//"Soundflower (2ch)"
	//"MOTU UltraLite mk3 Hybrid"
);
s.options.numOutputBusChannels_(2);
s.options.inDevice_("Built-in Microph");
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
//Object.browse; // also see Language->look up implementations
// s.plotTree;
// s.meter;

//2. initialize global variables
~out = 0;
~freqScope = FreqScope.new(400, 200, 0, server: s);

~reverbBus = Bus.audio(s,2);

~makeNodes = {
	s.bind({
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp);
		~reverbSynth = Synth.new(
			\reverb,
			[
				\amp, 1,
				\mix, 0.35,
				\room, 0.15,
				\damp, 0.5,
				\amp, 1.0,
				\in, ~reverbBus,
				\out, ~out,
			],
			~reverbGrp
		);
	});
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

//3. define piece-specific functions
~tempoClock = TempoClock.default;
~tempoClock.tempo = 120/60; //120 bpm 4/4
~makeEvents = {
	var indexOfOxy;
	MIDIClient.init;
	indexOfOxy = MIDIClient.sources.detectIndex({arg ep; ep.name.contains("Oxygen 8")});
	MIDIIn.connect(indexOfOxy, MIDIClient.sources[indexOfOxy]);
	~oxyKnobMap1= [71, 74, 84, 7,  91, 93, 5,  10];
	~oxyKnobMap2= [106,107,108,109,102,103,104,105]; // P10 == best

	e = Dictionary.new;

	~chorusRollRiff0 = Pseq([22, 22, 24, 22],inf);
	~chorusRollRiff1 = Pseq([22,22,22,22,24,24,24,24,28,28,22,22,24,24,24,24],inf);
	~chorusRollRiff2 = Pxrand((Scale.major.degrees+26),inf);
	~chorusRollRiff3 = Prand([30,28,32,34],inf);
	~chorusRollRiffFunc = Pfunc({~config[\chorus][\rollbase][\note]});

	~config = (
		bass:(note:30, dura:2, amp:0.8),
		snare:(note:30, dura:2, amp:0.4),
		hat:(note:110, dura:0.2, amp:0.0),
		tri:(note:123, dura:2, amp:0.0),
		chorus:(
			rollbase:(amp:2, note:22, riff:~chorusRollRiffFunc),
			twinkle:(amp:3, note:68)
		),
		midi:(map:~oxyKnobMap2)
	);

	e.add(\intro -> {
		Routine({
			~introSequence = Pbind(
				\instrument,\bpfsaw,
				\dur, 1, //Pexprand(0.1,1,inf),
				\freq, 4, //Pexprand(8,9,inf),
				\detune, 0,
				\rqmin, 0.005, \rqmaz, 0.008,
				\cfmin, Pseq([100, 200, 300, 400], inf), \cfmax, Pkey(\cfmin),
				\amp, 0.5,
				\out, ~out
			);

			~introPercussion = Ppar([
				Pbind(\instrument, \bass,
					\dur, 2,
					\amp, Pfunc({~config[\bass][\amp]}),
					\midinote, Pfunc({~config[\bass][\note]}),
					\dura, Pfunc({~config[\bass][\dura]}),
					\metal, 1.01,
					\group, ~mainGrp, \out, ~reverbBus),
				//Pbind(\instrument, \snare,\amp, 0.8, \cut_freq, 4000, \dur, 4,  \dura, 0.2),
				Pbind(\instrument, \hat,
					\dur, 0.5,
					\amp, Pfunc({~config[\hat][\amp]}),
					\midinote, Pfunc({~config[\hat][\note]}),
					\dura,  Pfunc({~config[\hat][\dura]}),
					\group, ~mainGrp, \out, ~reverbBus),
				/*triangle*/
				Pbind(\instrument, \bass,
					\dur, 8,
					\amp, Pfunc({~config[\tri][\amp]}),
					\midinote, Pfunc({~config[\tri][\note]}),
					\dura,  Pfunc({~config[\tri][\dura]}),
					\group, ~mainGrp, \out, ~reverbBus)
			]);

			~intro = Pdef(\intro, Ppar([ ~introPercussion, ~introSequence]));
			~intro.quant = [~tempoClock.beatsPerBar];
			~intro.play;
			4.wait;

			~chorus.stop;

		}).play();
	});

	e.add(\introStop -> {
		~intro.stop;
	});

	e.add(\chorus -> {
		Routine({
			~chorusSequence  = Ppar([
				// rollBase: use bpfsaw for rolling bass w. sloping reverse envelopes and var blowshelf
				Pbind(\instrument,\bpfsaw,	\dur, 1,
					\amp, Pfunc({~config[\chorus][\rollbase][\amp]}),
					\midinote, ~config[\chorus][\rollbase][\riff],////Pdefn(\riff,~rollriff0)
					\pre, 0.5, \atk, 0.2, \sus, 0.278, \rel, 0.1,
					\rqmin, 0.2, \rqmax, 0.3, \cfhzmin, 0, \cfhzmax, 0,
					\cfmin, 25, \cfmax, 40,
					\out, ~out
				),
				// twinkle:
				Pbind(\instrument, \bpfsaw, \dur, 0.5,
					\amp, Pfunc({~config[\chorus][\twinkle][\amp]}),
					\midinote, Pfunc({~config[\chorus][\twinkle][\note]}),
					\detune, 0,
					\atk, 0,\rel, 1,
					\rqmin, 0.0005, \rqmax, 0.008,
					\cfmin, 200, \cfmax, 1000,
					\out, ~out
				),
			]);

			~chorusPercussion  = Ppar([
				Pbind(\instrument, \bass, \dur, 1,
					\amp, Pfunc({~config[\bass][\amp]}),
					\midinote, Pfunc({~config[\bass][\note]}),
					\dura, Pfunc({~config[\bass][\dura]}),
					\metal, 1.1,
					\group, ~mainGrp, \out, ~reverbBus),
				Pbind(\instrument, \hat,  \dur, 1,
					\amp, Pfunc({~config[\hat][\amp]}),
					\midinote, Pfunc({~config[\hat][\note]}),
					\dura,  Pfunc({~config[\hat][\dura]}),
					\group, ~mainGrp, \out, ~reverbBus),
				/*triangle*/
				Pbind(\instrument, \bass,  \dur, 0.5,
					\amp, Pfunc({~config[\tri][\amp]}),
					\midinote, Pfunc({~config[\tri][\note]}),
					\dura,  Pfunc({~config[\tri][\dura]}),
					\group, ~mainGrp, \out, ~reverbBus),
			]);


			~chorus = Pdef(\chorus, Ppar([ ~chorusPercussion, ~chorusSequence]));
			~chorus.quant = [~tempoClock.beatsPerBar];
			~chorus.play;
			// delay here might not need it
			4.wait;

			~intro.stop;
		}).play();
	});

	e.add(\chorusStop -> {
		~chorus.stop;
	});

	MIDIdef.cc(\controller, {|val, ctnum, chan|
		var map;
		map = ~config[\midi][\map];
		//["controller", val, ctnum, chan].postln;
		switch (ctnum)
		{map[0]} { // topleft knob:
			~config[\chorus][\twinkle][\amp] = val.linlin(0,127,0,3);
		}
		{map[1] } { // 2nd top left knob:
			~config[\chorus][\rollbase][\amp] = val.linlin(0,127,0,3);
		}
		{map[2]} { //2nd top right knob:
			~config[\bass][\amp] = val.linlin(0,127,0,1);
		}
		{map[3] } { // top right knob:
			~config[\snare][\amp] = val.linlin(0,127,0,1);
		}
		{map[4] } { //  bottom left:
			~config[\hat][\amp] = val.linlin(0,127,0,1);
		}
		{map[5] } { //  bottom 2nd left:
			~config[\tri][\amp] = val.linlin(0,127,0,0.5);
		}
		{map[6]} { // bottom 2nd right:

		}
		{map[7] } { // bottom right:

		}
		{"unmapped:"+chan +":"+ ctnum + " -> "+val}.postln
		;
	});

	MIDIdef.noteOn(\noteOn,{|vel, nn, chan, s|
		["noteOn", vel, nn, chan, s].postln;
		~config[\chorus][\rollbase][\note] = nn
	});

	MIDIdef.noteOff(\noteOff,{|vel, nn, chan, s|
		["noteOff", vel, nn, chan, s].postln;

	});

	MIDIdef.bend(\bend,{|vel, nn, chan, s|
		["bend", vel, nn, chan, s].postln;

	});

};

//4. register functions with ServerBoot/Quit/Tree
ServerQuit.add(~cleanup);

//5. boot server
s.waitForBoot({

	s.sync;

	//6a. SynthDefs
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
			sig = Balance2.ar(sig[0], sig[1], pan);
			sig = sig * env * amp;
			Out.ar(~out, sig)
		}).add;

		/* ----------------------
		Synthetic bass drum
		---------------------- */
		SynthDef(\bass, {
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
			arg out, mix = 0.25, room = 0.15, damp = 0.5, amp = 1.0;
			var signal;

			signal = In.ar(~reverbBus, 2);

			Out.ar(out,
				FreeVerb2.ar( // FreeVerb2 - true stereo UGen
					signal[0], // Left channel
					signal[1], // Right Channel
					mix, room, damp, amp
				)
			); // same params as FreeVerb 1 chn version

		}).add;
	);

	s.sync;

	//6b. register remaining functions
	ServerTree.add(~makeNodes);
	ServerTree.add(~makeEvents);
	s.freeAll;

	s.sync;

	"done".postln;

});
)
/////////////// test ///////////////////////////////
~tempoClock.tempo = 122/60;
e[\intro].()
e[\introStop].()
e[\chorus].()
e[\chorusStop].()

~reverbSynth.set(\mix, 0.3, \room, 1, \damp, 1)
~config[\bass].putPairs([\note, [28,30,32,34,35].choose, \dura, 2]);
~config[\chorus][\rollbase].putPairs([\riff,~chorusRollRiffFunc, \note, 28, \amp, 3]);
~config[\chorus][\twinkle].putPairs([\note, 40, \amp, 5]);
~config[\chorus][\rollbase][\riff] = ~chorusRollRiff0;
~config[\chorus][\rollbase][\riff] = ~chorusRollRiff1;
~config[\tri][\note] = {(Scale.major.degrees[7.rand]+108)}.value() // todo retrigger somehow
~config[\tri][\dura] = 1

x = ~introPercussion.play
x.stop
~bassTest = Synth.new(\bass,[\amp,0.9,\freq, 40, \dura, 5, \metal, 1.01, \out:~reverbBus])
s.meter;

////////////////////// OLD code (yuk - del) ////////////////////////
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


~bassTest = Synth.new(\bass,[\amp,0.8,\freq,50 /* 20 bass - 200 tom*/, \dura, 1])
~glockTest = Synth.new(\bass,[\amp,0.8,\freq,1200]) // mid freq is glock 400-1800, high is triangle 2k-20k
~snareTest = Synth.new(\snare,[\amp,0.8,\cut_freq,1000 /* 200-20000*/, \dur, 0.2 /* 0.05 - 1 */])
~hatTest = Synth.new(\hat,[\amp,0.8,\cut_freq,4000 /* 2000 heavy - 20000 lightest*/, \dur, 0.8 /* 0.05 closed - 1 open */])


////////////////////// sequencing ////////////////////////////////////////
(
c = TempoClock.default;
c.tempo = 120/60; //120 bpm 4/4
Pdef(\bassline).quant = [c.beatsPerBar];
~introSequence = Ppar([
		Pbind(\instrument, \bass, \amp, 0.8, \freq, 20,       \dur, 2,  \dura, 0.6, \metal, 1.2),
		//Pbind(\instrument, \snare,\amp, 0.8, \cut_freq, 4000, \dur, 4,  \dura, 0.2),
		Pbind(\instrument, \hat,  \amp, 0.4, \cut_freq, 5000, \dur, 0.5, \dura, 0.2),
		Pbind(\instrument, \bass, \amp, 0.04, \freq, 10000, \dur, 8, \dura, 2),
		~marimbaIntro
	]);
~rollRiff0 = Pseq([22].midicps,inf);
~rollRiff1 = Pseq([22,22,22,22,24,24,24,24,28,28,22,22,24,24,24,24].midicps,inf);
~rollRiff2 = Pxrand((Scale.major.degrees+26).midicps,inf);
~rollRiff3 = Prand([30,28,32,34].midicps,inf);
// seq 16 subunits: /dur = Pseq(1,5,8,13,15).func(n+1 - n)/16*barDuration
//Pseq([~rollRiff1,~rollRiff0,~rollRiff0,~rollRiff2,~rollRiff0,~rollRiff3,~rollRiff0,~rollRiff0],inf)
~chorusSequence  = Ppar([
	Pbind(\instrument, \bass, \amp, 0.8, \freq, 20,       \dur, 1,  \dura, 0.3, \metal, 1.1),
	// Pbind(\instrument, \bass, \amp, 0.8, \freq, 20,       \dur, Pseq([0.25,0.25,0.5], inf),  \dura, 0.3, \metal, 1.1),
		//Pbind(\instrument, \snare,\amp, 0.8, \cut_freq, 4000, \dur, 4,  \dura, 0.2),
		Pbind(\instrument, \hat,  \amp, 0.4, \cut_freq, 5000, \dur, 1, \dura, 0.2),
	Pbind(\instrument, \bass, \amp, 0.04, \freq, Prand((Scale.major.degrees+108).midicps,inf), \dur, 0.5, \dura, 0.5),
	// use bpfsaw for rolling bass w. sloping reverse envelopes and var blowshelf
	Pbind(\instrument,\bpfsaw,	\dur, 1,\amp,2,\freq,~rollRiff0,\pre, 0.5,
		\atk,0.2,\sus,0.278,\rel,0.1,
		\rqmin, 0.2,\rqmax, 0.3,\cfhzmin,0,\cfhzmax,0,
		\cfmin,25,\cfmax,40),
	Pbind(\instrument,\bpfsaw,\dur,0.5,\amp,3,\freq,400,\detune,0,
		\atk, 0,\rel,1,
		\rqmin, 0.0005,\rqmax, 0.008,
		\cfmin,200, \cfmax,1000),
	]);



Pdef(\bassline,
	//~introSequence
	 ~chorusSequence
).play;
)
Pdef(\bassline).stop;


///////////////// testing ///////////////////////////////////
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
