

// setup ///////////
(
Server.default.options.inDevice_("UMC404HD 192k");
Server.default.options.outDevice_("Built-in Output");// UMC404HD 192k <- weird crackling ...
Server.default.options.blockSize = 512;
s.boot;
// ServerOptions.inDevices;
 ServerOptions.outDevices;
~thereminBus = Bus.audio(s,2);
)

// tools //////
s.plotTree
// synths ///////////////
(
SynthDef(\thereminInput, {
	arg inamp = 3, out = 0;
	var sig;
	sig = In.ar(2,[3]) ! 2  * inamp;
	//sig.scope;
	Out.ar(out, sig);
}).add;

SynthDef(\thereminFollow, { |in, out, gain|
	var sig, amp, freq, hasFreq, sound;
	// sig = Mix.new(SoundIn.ar([0, 1]));
	sig = In.ar(in,2);
	amp = Amplitude.kr(sig, 0.05, 0.05);
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
	sound = Mix.new(VarSaw.ar(freq * [0.5, 1, 2], 0, LFNoise1.kr(0.3, 0.1, 0.1), amp));
	6.do {
		sound = AllpassN.ar(sound, 0.040, [0.040.rand,0.040.rand], 2) * gain
	};
	Out.ar(out, sound);
}).add;

SynthDef(\thereminPitch, {
	arg in=0, out=0,gain=1, deltime=0.3,
	pitchRatio=1, pitchGrainSize=0.01, pitchDispersion=0, timeDispersion=0,
	tempo=120, clip=1, bpfSweepRatio=0.1, bpfRecipQ=1, delayTempoRatio=1, transRatio=1, transWidth=1;
	var sig, delay, clipamp, freq, hasFreq, test;
	sig = In.ar(in,1) ! 2;
	sig = HPF.ar(HPF.ar(sig, 100), 20);
	# freq, hasFreq = Pitch.kr(sig, ampThreshold: 0.02, median: 7);
	sig = PitchShift.ar(sig, 0.1, pitchRatio, pitchDispersion, timeDispersion);
	clipamp = Amplitude.kr(sig, 0.05, 0.05);
	sig = sig.clip2(clip) * clipamp / clip;
	test = sig;test.scope;
	//
	 freq=freq*pitchRatio/2;
	 sig = BPF.ar(sig, SinOsc.kr(tempo / 60, mul: freq * bpfSweepRatio, add: freq), bpfRecipQ);
	delay = HPF.ar(DelayL.ar(sig, 1, tempo / 60 * delayTempoRatio ), 100);
	sig = XFade2.ar(sig, delay, -0.5) * gain;
	sig = sig * EnvGen.ar(Env.asr(0.01, 0.5, 0.01,curve: 'sin'), LFPulse.ar(tempo / 60 * transRatio, width: transWidth));
	sig = Pan2.ar(sig, 0.5) !2;
	//sig = Normalizer.ar(in: sig, level: 1.0, dur: 0.01);
	// create a new analyzer
	FreqScope.new(400, 200, 0, server: s);

	Out.ar(out, sig);
}).add;

SynthDef(\ping, {
	arg out=0, gate = 0, amp=0.5;
	var sig;
	sig = EnvGen.ar(Env.asr(0.01, 0.5, 0.01,curve: 'sin'), gate) * SinOsc.ar(440);
	Out.ar(out, sig);
}).add;

////////////////////// midi - oxy 8 ////////////////////////////
(
MIDIClient.init;
MIDIClient.sources;
MIDIIn.connect(2, MIDIClient.sources.at(2));  // MIDIEndPoint("USB Oxygen 8 v2", "USB Oxygen 8 v2")
~map1= [71, 74, 84, 7,  91, 93, 5,  10];
~map2= [106,107,108,109,102,103,104,105];
~map = ~map2;
MIDIdef.cc(\ccTheremin,{|val, ctnum, chan|
	["\ccTheremin", val, ctnum, chan].postln;
	c = switch (ctnum)
	{1} {// mod wheel : pitch

	}
	{ ~map[0]} { // topleft knob:  \fCenter
		~thereminPitch.set(\bpfRecipQ, val.linexp(0,127, 0.1, 1));
	}
	{~map[1] } { // 2nd top left knob: \fWid
		~thereminPitch.set(\bpfSweepRatio, val.linexp(0, 127, 0.01, 0.9));
	}
	{~map[2]} { //2nd top right knob: clip
		~thereminPitch.set(\clip, val.linlin(0,127, 0.01,1));
	}
	{~map[3] } { // top right knob: \delayTempoRatio
		~thereminPitch.set(\delayTempoRatio, 2.pow(val.linlin(0,127, 2, -6).trunc));
	}
	{~map[4] } { //  bottom left:
		 ~thereminPitch.set(\gain, val.linexp(0,127, 0.001, 30));
		//~thereminPitch.set(\pitchRatio, val.linexp(0,127, 0.25,4));
	}
	{~map[5] } { //  bottom 2nd left: pitch variance
		~thereminPitch.set(\pitchDispersion, val.linexp(0,127, 0.01,1)-0.01);
	}
	{ ~map[6]} { // bottom 2nd right: \transRatio
		~thereminPitch.set(\transRatio, 2.pow(val.linlin(0,127, -4, 4).trunc));
	}
	{ ~map[7] } { // bottom right: transWidth
		~thereminPitch.set(\transWidth, val.linlin(0,127, 0,1));
	}
	{20} {// reload button (left)

	}
	{21} {// << button (left)

	}
	{22} {// >> button (left)

	}
	{23} {// [] button (left)

	}
	{24} {// > button (left)

	}
	{25} {// record button (left)
		if(~pingVal==1,{~pingVal=0},{~pingVal=1});
		~pingVal.postln;
		~ping.set(\gate,~pingVal);
	}

	{"unmapped:"+chan +":"+ ctnum + " -> "+val};
});

MIDIdef.noteOn(\noteTheremin,{|vel, nn, chan, s|
	["noteon",vel, nn, chan, s].postln;
	~thereminPitch.set(\pitchRatio, nn.linexp(40,88, 0.25,4));
	});
)

)

(
~thereminInGrp = Group.new;
~thereminEffectsGrp = Group.after(~thereminInGrp);
~thereminInput = Synth(\thereminInput,[\out, ~thereminBus,\inamp, 1], ~thereminInGrp);
~thereminPitch = Synth(\thereminPitch,[\in, ~thereminBus, \out, 0], ~thereminEffectsGrp);
~thereminPitch.set(\tempo,125);
~ping = Synth(\ping,[\out, 0], ~thereminEffectsGrp);
//~thereminFollow = Synth(\thereminFollow,[\in,~thereminBus, \out, 0, \gain, 0.5], ~thereminEffectsGrp);
)
(
~thereminInGrp.free;
~thereminEffectsGrp.free;
)
~thereminPitch.set(\pitchRatio, 1, \pitchDispersion, 0.5, \timeDispersion, 0);
~thereminPitch.set(\tempo,144);
~thereminPitch.set(\delayTempoRatio, 0.5);
~thereminPitch.set(\transRatio, 6);
~thereminPitch.set(\gain, 4);
~thereminPitch.set(\transWidth, 0.05);
~thereminPitch.set(\clip, 0.4, \bpfSweepRatio, 50, \bpfRecipQ, 1000);
~ping.set(\gate,1);
~ping.set(\gate,0);
~pingVal = 1;// for toggle;

//////// args ////////////////////////////////////////////////////
(
~thereminPitchArgs = [
	\in, ~thereminBus,
	\out, 0,
	\pitchRatio, 1,
	\pitchDispersion, 0.5,
	\timeDispersion, 0,
	\tempo, 133.58,
	\delayTempoRatio, 0.5,
	\transRatio, 0.5,
	\transWidth, 0.4,
	\clip, 0.4,
	\bpfSweepRatio, 50,
	\bpfRecipQ, 1
];
~thereminPitchArgs.put(7, 0.7);
~thereminPitch.set(~thereminPitchArgs);
~thereminPitchArgs.postln()
)
~thereminPitch.getnMsg(0, 0).postln
~thereminPitch.get(\pitchRatio, { arg value; ("\pitchRatio is now: " + value + "x").postln; });

//////// inputs testing ////////////////////////
{ In.ar(2,[3]) }.play; // input 1
{ In.ar(2,[4]) }.play; // input 2
{ In.ar(2,[5]) }.play; // input 3
{ In.ar(2,[6]) }.play; // input 4

/*var buffer = Buffer.alloc(s, 1024, 1);
	var chain = FFT(buffer, in);*/


// pulse width modulation
(
{ LFPulse.ar(100,0,MouseY.kr(0,1),0.1) }.scope(1, zoom: 4);
{ LFPulse.ar(100,0,LFTri.kr(0.2,0,0.5,0.5),0.1) }.scope(1, zoom: 4);
)

{ LPF.ar(Saw.ar(200,0.1), SinOsc.kr(XLine.kr(0.7,300,20),0,3600,4000)) }.play;
{ SinOsc.ar(300, 0, MouseX.kr(0.1,80,1)).distort * 0.2 }.scope(1);
{ SinOsc.ar(300, 0, MouseX.kr(0.1,80,1)).clip2(1) * 0.2 }.scope(1);

{SinOsc.ar(300)*EnvGen.ar(Env.asr(0.01, 0.5, 0.01, 1,curve: 'sin'),LFPulse.ar(8, width: 0.5))}.play